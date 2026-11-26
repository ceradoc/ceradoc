# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Ceradoc::Incremental do
  def sidecar_at(dir)
    Ceradoc::SourceGraph::Sidecar.new(File.join(dir, 'cache'))
  end

  def write(dir, name, content)
    path = File.expand_path(File.join(dir, name))
    File.write(path, content)
    path
  end

  def build_graph(paths, sidecar)
    Ceradoc::SourceGraph.build(paths, sidecar: sidecar)
  end

  # root -> intro -> detail, and root -> summary. Editing detail must
  # reparse detail, intro, root — and nothing else.
  def fanout_graph(dir)
    detail = write(dir, 'detail.adoc', "detail\n")
    intro = write(dir, 'intro.adoc', "intro\n\ninclude::detail.adoc[]\n")
    summary = write(dir, 'summary.adoc', "summary\n")
    root = write(dir, 'root.adoc',
                 "= R\n\ninclude::intro.adoc[]\n\ninclude::summary.adoc[]\n")
    graph = build_graph(root, sidecar_at(dir))
    paths = { 'root.adoc' => root, 'intro.adoc' => intro,
              'summary.adoc' => summary, 'detail.adoc' => detail }
    paths.each_value { |path| graph.materialize(graph.node(path)) }
    [graph, paths]
  end

  describe '.plan' do
    it 'reparse is exactly the changed page plus its transitive includers' do
      Dir.mktmpdir do |dir|
        graph, paths = fanout_graph(dir)

        plan = described_class.plan(graph, changed: paths['detail.adoc'])

        expect(plan[:reparse]).to eq(
          [paths['detail.adoc'], paths['intro.adoc'], paths['root.adoc']].sort
        )
        expect(plan[:reuse]).to eq([paths['summary.adoc']])
      end
    end

    it 'is pure: planning demotes nothing' do
      Dir.mktmpdir do |dir|
        graph, _paths = fanout_graph(dir)

        described_class.plan(graph, changed: File.join(dir, 'detail.adoc'))

        expect(graph.nodes).to all(be_parsed)
      end
    end

    it 'is deterministic: the same inputs produce the same plan' do
      Dir.mktmpdir do |dir|
        graph, paths = fanout_graph(dir)

        first = described_class.plan(graph, changed: paths['detail.adoc'])
        second = described_class.plan(graph, changed: paths['detail.adoc'])

        expect(first).to eq(second)
      end
    end

    it 'plans cross-format closures' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.md', "included text\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.md[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        graph.materialize(graph.node(doc))
        graph.materialize(graph.node(part))

        plan = described_class.plan(graph, changed: part)

        expect(plan[:reparse]).to eq([doc, part].sort)
        expect(plan[:reuse]).to be_empty
      end
    end

    it 'reparse includes an untracked changed path, closing over no edges' do
      Dir.mktmpdir do |dir|
        graph, paths = fanout_graph(dir)
        outsider = write(dir, 'outsider.adoc', "new page\n")

        plan = described_class.plan(graph, changed: outsider)

        expect(plan[:reparse]).to eq([outsider])
        expect(plan[:reuse]).to eq(
          [paths['detail.adoc'], paths['intro.adoc'],
           paths['root.adoc'], paths['summary.adoc']].sort
        )
      end
    end

    it 'with no changes, everything tracked is reusable' do
      Dir.mktmpdir do |dir|
        graph, paths = fanout_graph(dir)

        plan = described_class.plan(graph, changed: [])

        expect(plan[:reparse]).to be_empty
        expect(plan[:reuse]).to eq(paths.values.sort)
      end
    end
  end
end
