# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

RSpec.describe Ceradoc::SourceGraph do
  def sidecar_at(dir)
    Ceradoc::SourceGraph::Sidecar.new(File.join(dir, 'cache'))
  end

  def write(dir, name, content)
    File.write(File.join(dir, name), content)
    File.join(dir, name)
  end

  def build_graph(paths, sidecar)
    Ceradoc::SourceGraph.build(paths, sidecar: sidecar)
  end

  describe 'lazy levels' do
    it 'does not parse until asked' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.parsed?).to be(false)
        expect(node.derived_digest).to be_nil
      end
    end

    it 'parses to the format tree and materializes CoreModel' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.parsed).to be_a(Ceradoc::AsciiDoc::Model::Document)
        core = graph.materialize(node)
        expect(core).to be_a(Ceradoc::CoreModel::DocumentElement)
        expect(node.parsed?).to be(true)
        expect(node.derived_digest).to match(/\A[0-9a-f]{64}\z/)
      end
    end

    it 'caches the CoreModel materialization' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.core).to equal(node.core)
      end
    end

    it 'raises for an unregistered extension' do
      Dir.mktmpdir do |dir|
        blob = write(dir, 'blob.xyz', 'content')
        node = build_graph(blob, sidecar_at(dir)).node(blob)

        expect { node.parsed }
          .to raise_error(Ceradoc::UnsupportedFormatError)
      end
    end
  end

  describe 'freshness and demotion' do
    it 'reports a content-edited node as stale and demotes it' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)

        write(dir, 'doc.adoc', "= Title\n\nedited\n")
        stale = graph.stale_nodes

        expect(stale.map(&:path)).to contain_exactly(node.path)
        expect(node.parsed?).to be(false)
      end
    end

    it 'propagates staleness up the include edges' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)

        expect(graph.edges(doc)).to eq([File.expand_path(part)])

        write(dir, 'part.adoc', "changed\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        # part has no derived state in a cold graph, so only the
        # includer is stale — but its parsed level is demoted.
        expect(stale).to eq(%w[doc.adoc])
        expect(node.parsed?).to be(false)
      end
    end

    it 'treats .md includes as edges: touching the .md part stales the .adoc host' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.md', "# Part heading\n\nmd body\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.md[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)

        # The .md edge is recorded like any include edge: the host's
        # materialized CoreModel holds the Include link node, and the
        # graph digest covers the .md part's content digest.
        expect(graph.edges(doc)).to eq([File.expand_path(part)])
        includes = node.core.children.grep(Ceradoc::CoreModel::Include)
        expect(includes.map(&:target)).to eq(['part.md'])

        write(dir, 'part.md', "# Part heading\n\nchanged\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        expect(stale).to eq(%w[doc.adoc])
        expect(node.parsed?).to be(false)
      end
    end

    it 'propagates transitively through chains' do
      Dir.mktmpdir do |dir|
        write(dir, 'leaf.adoc', "leaf\n")
        mid = write(dir, 'mid.adoc', "mid\n\ninclude::leaf.adoc[]\n")
        root = write(dir, 'root.adoc', "= R\n\ninclude::mid.adoc[]\n")
        graph = build_graph(root, sidecar_at(dir))
        root_node = graph.node(root)
        graph.materialize(root_node)
        graph.materialize(graph.node(mid))

        write(dir, 'leaf.adoc', "leaf2\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        # leaf was never materialized; both includers are stale.
        expect(stale.sort).to eq(%w[mid.adoc root.adoc])
      end
    end

    it 'terminates on circular includes' do
      Dir.mktmpdir do |dir|
        a = write(dir, 'a.adoc', "a\n\ninclude::b.adoc[]\n")
        b = write(dir, 'b.adoc', "b\n\ninclude::a.adoc[]\n")
        graph = build_graph(a, sidecar_at(dir))
        node = graph.node(a)
        graph.materialize(node)
        graph.materialize(graph.node(b))

        write(dir, 'b.adoc', "b2\n\ninclude::a.adoc[]\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        expect(stale.sort).to eq(%w[a.adoc b.adoc])
      end
    end

    it 'flags the includer when a NEW include appears (structural drift)' do
      Dir.mktmpdir do |dir|
        write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist

        write(dir, 'new.adoc', "new\n")
        write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n\ninclude::new.adoc[]\n")

        expect(graph.stale_nodes.map(&:path)).to contain_exactly(node.path)
      end
    end
  end

  describe Ceradoc::SourceGraph::Sidecar do
    it 'prefers CERADOC_CACHE_DIR, then XDG_CACHE_HOME, then ~/.cache' do
      old = [ENV.fetch('CERADOC_CACHE_DIR', nil), ENV.fetch('XDG_CACHE_HOME', nil)]
      begin
        ENV['CERADOC_CACHE_DIR'] = '/tmp/ceradoc-override'
        expect(described_class.default_dir).to eq('/tmp/ceradoc-override')

        ENV['CERADOC_CACHE_DIR'] = nil
        ENV['XDG_CACHE_HOME'] = '/tmp/xdg-home'
        expect(described_class.default_dir).to eq('/tmp/xdg-home/ceradoc')

        ENV['XDG_CACHE_HOME'] = nil
        expect(described_class.default_dir)
          .to eq(File.join(Dir.home, '.cache', 'ceradoc'))
      ensure
        ENV['CERADOC_CACHE_DIR'], ENV['XDG_CACHE_HOME'] = old
      end
    end

    it 'round-trips digests, edges, and lazily minted ids' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist

        payload = JSON.parse(File.read(sidecar_at(dir).path))
        doc_record = payload[File.expand_path(doc)]
        part_record = payload[File.expand_path(part)]

        expect(doc_record['edges']).to eq([File.expand_path(part)])
        expect(doc_record['digest']).to eq(node.derived_digest)
        expect(doc_record['id']).to match(/\An\d{8}\z/)
        expect(part_record['id']).to match(/\An\d{8}\z/)
        expect(part_record['id']).not_to eq(doc_record['id'])
      end
    end

    it 'keeps ids stable across rewrites' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist
        first_id = sidecar_at(dir).record_for(doc)['id']

        graph.persist

        expect(sidecar_at(dir).record_for(doc)['id']).to eq(first_id)
      end
    end

    it 'evicts the oldest records beyond the cap' do
      Dir.mktmpdir do |dir|
        sidecar = sidecar_at(dir)
        records = (1..3).map do |i|
          { path: File.join(dir, "f#{i}.adoc"), id: nil,
            digest: "d#{i}", edges: [] }
        end
        stub_const("#{described_class}::MAX_ENTRIES", 2)
        sidecar.write(records)

        keys = sidecar.entries.keys.map { |p| File.basename(p) }
        expect(keys).to eq(%w[f2.adoc f3.adoc])
      end
    end

    it 'treats a corrupt cache file as empty' do
      Dir.mktmpdir do |dir|
        sidecar = sidecar_at(dir)
        FileUtils.mkdir_p(sidecar.dir)
        File.write(sidecar.path, '{not json')

        expect(sidecar.entries).to eq({})
      end
    end
  end

  describe 'warm rebuilds' do
    it 'reuses digests without parsing and reports no stale nodes' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        write(dir, 'part.adoc', "included\n")
        cold = build_graph(doc, sidecar_at(dir))
        cold.materialize(cold.node(doc))
        cold_digest = cold.node(doc).derived_digest
        cold.persist

        warm = build_graph(doc, sidecar_at(dir))
        warm_node = warm.node(doc)

        expect(warm.stale_nodes).to be_empty
        expect(warm_node.digest).to eq(cold_digest)
        expect(warm_node.parsed?).to be(false)

        write(dir, 'part.adoc', "changed\n")
        expect(warm.stale_nodes.map { |n| File.basename(n.path) }.sort)
          .to eq(%w[doc.adoc part.adoc])
      end
    end
  end

  describe 'minimal reparse set (#383)' do
    # root -> intro -> detail, and root -> summary: editing detail
    # must reparse detail, intro, root — and nothing else. Fully built
    # tree, as after a complete previous build.
    def fanout_tree(dir)
      detail = write(dir, 'detail.adoc', "detail\n")
      intro = write(dir, 'intro.adoc', "intro\n\ninclude::detail.adoc[]\n")
      summary = write(dir, 'summary.adoc', "summary\n")
      root = write(dir, 'root.adoc',
                   "= R\n\ninclude::intro.adoc[]\n\ninclude::summary.adoc[]\n")
      graph = build_graph(root, sidecar_at(dir))
      nodes = [detail, intro, summary, root].map { |path| graph.node(path) }
      nodes.each { |node| graph.materialize(node) }
      [graph, nodes]
    end

    it 'stale_nodes is exactly the edited page plus its transitive includers' do
      Dir.mktmpdir do |dir|
        graph, _nodes = fanout_tree(dir)

        write(dir, 'detail.adoc', "detail2\n")
        stale = graph.stale_nodes

        expect(stale.map { |n| File.basename(n.path) })
          .to eq(%w[detail.adoc intro.adoc root.adoc])
      end
    end

    it 'demotes exactly the reparse set; untouched subtrees stay parsed' do
      Dir.mktmpdir do |dir|
        graph, nodes = fanout_tree(dir)
        by_name = nodes.to_h { |n| [File.basename(n.path), n] }

        write(dir, 'detail.adoc', "detail2\n")
        graph.stale_nodes

        expect(by_name['detail.adoc']).not_to be_parsed
        expect(by_name['intro.adoc']).not_to be_parsed
        expect(by_name['root.adoc']).not_to be_parsed
        expect(by_name['summary.adoc']).to be_parsed
      end
    end

    it 'reparse_set plans the closure without demoting anything' do
      Dir.mktmpdir do |dir|
        graph, nodes = fanout_tree(dir)
        detail = File.join(dir, 'detail.adoc')

        set = graph.reparse_set(detail)

        expect(set).to eq(
          [detail, File.join(dir, 'intro.adoc'), File.join(dir, 'root.adoc')]
            .map { |path| File.expand_path(path) }.sort
        )
        expect(nodes).to all(be_parsed)
      end
    end

    it 'closes over cross-format include edges' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.md', "included text\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.md[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        graph.materialize(graph.node(doc))
        graph.materialize(graph.node(part))
        expect(graph.edges(doc)).to eq([File.expand_path(part)])

        write(dir, 'part.md', "changed text\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        expect(stale).to eq(%w[doc.adoc part.md])
      end
    end
  end

  describe '.node_digest' do
    it 'produces the same digest for the same content parsed independently' do
      Dir.mktmpdir do |dir|
        text = "= Title\n\nbody\n"
        a = write(dir, 'a.adoc', text)
        b = write(dir, 'b.adoc', text)
        graph_a = build_graph(a, sidecar_at(dir))
        graph_b = build_graph(b, sidecar_at(dir))

        digest_a = described_class.node_digest(graph_a.node(a))
        digest_b = described_class.node_digest(graph_b.node(b))

        expect(digest_a).to eq(digest_b)
        expect(digest_a).to match(/\A[0-9a-f]{64}\z/)
      end
    end

    it 'changes when the parsed content changes' do
      Dir.mktmpdir do |dir|
        a = write(dir, 'a.adoc', "= Title\n\nbody one\n")
        b = write(dir, 'b.adoc', "= Title\n\nbody two\n")
        graph_a = build_graph(a, sidecar_at(dir))
        graph_b = build_graph(b, sidecar_at(dir))

        expect(described_class.node_digest(graph_a.node(a)))
          .not_to eq(described_class.node_digest(graph_b.node(b)))
      end
    end

    it 'is stable across a rebuild with a fresh sidecar' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        write(dir, 'part.adoc', "part\n")
        cold = build_graph(doc, sidecar_at(dir))
        cold.materialize(cold.node(doc))
        first = described_class.node_digest(cold.node(doc))

        fresh = described_class.build(
          doc,
          sidecar: Ceradoc::SourceGraph::Sidecar.new(File.join(dir, 'cache2'))
        )

        expect(described_class.node_digest(fresh.node(doc))).to eq(first)
      end
    end

    it 'excludes positional bookkeeping (source_line)' do
      near = Ceradoc::CoreModel::ElementAttribute.new(
        name: 'role', value: 'note', source_line: 3
      )
      far = Ceradoc::CoreModel::ElementAttribute.new(
        name: 'role', value: 'note', source_line: 40
      )
      other = Ceradoc::CoreModel::ElementAttribute.new(
        name: 'role', value: 'tip', source_line: 3
      )
      digest_of = Ceradoc::SourceGraph::ModelDigest

      expect(digest_of.of(near)).to eq(digest_of.of(far))
      expect(digest_of.of(near)).not_to eq(digest_of.of(other))
    end

    it 'is identical across processes (no object ids, no hash order)' do
      text = "= T\n\nSome paragraph.\n\ninclude::part.adoc[]\n"
      in_process = Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', text)
        write(dir, 'part.adoc', "part\n")
        graph = build_graph(doc, sidecar_at(dir))
        described_class.node_digest(graph.node(doc))
      end

      script = <<~RUBY
        require 'bundler/setup'
        require 'ceradoc'
        require 'ceradoc/asciidoc'
        require 'tmpdir'
        text = #{text.inspect}
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, 'doc.adoc'), text)
          File.write(File.join(dir, 'part.adoc'), "part\\n")
          graph = Ceradoc::SourceGraph.build(
            File.join(dir, 'doc.adoc'),
            sidecar: Ceradoc::SourceGraph::Sidecar.new(File.join(dir, 'cache'))
          )
          puts Ceradoc::SourceGraph.node_digest(graph.node(File.join(dir, 'doc.adoc')))
        end
      RUBY

      out, status = Open3.capture2(Gem.ruby, '-e', script)
      expect(status).to be_success
      expect(out.strip).to eq(in_process)
    end
  end
end
