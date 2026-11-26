# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'pathname'

# Mixed AsciiDoc/Markdown document trees (#380).
#
# Include resolution dispatches on the TARGET FILE EXTENSION through the
# format registry: a .md target inside an .adoc tree splices
# markdown-parsed CoreModel content, and the reverse. Findings ride the
# #377 Diagnostic currency under the INC rule family. The resolved tree
# is a VIEW — write-back serializes each FILE in its own format, and the
# host's Include edge survives because resolution never mutates its
# input.
RSpec.describe 'mixed adoc/markdown include trees', :asciidoc do
  # The roundtrip Projection module reduces CoreModel trees to plain
  # data for structural comparison (dropping positional source_line).
  # Load it from the monorepo roundtrip gem when present; fall back to
  # an inline replica with the same lutaml-based reduction otherwise.
  roundtrip_lib = File.expand_path('../../../roundtrip/lib', __dir__)
  if File.directory?(roundtrip_lib)
    $LOAD_PATH.unshift(roundtrip_lib) unless $LOAD_PATH.include?(roundtrip_lib)
    require 'ceradoc/roundtrip/projection'
  end

  def projection_of(node)
    return Ceradoc::Roundtrip::Projection.of(node) if defined?(Ceradoc::Roundtrip::Projection)

    inline_projection(node)
  end

  def inline_projection(node)
    ignored = %i[source_line]
    case node
    when Lutaml::Model::Serializable
      attrs = node.class.attributes.keys - ignored
      attrs.each_with_object({ '@type' => node.class.name.split('::').last }) do |name, hash|
        value = inline_projection(node.public_send(name))
        hash[name.to_s] = value unless value.nil? || value == []
      end
    when Array then node.map { |child| inline_projection(child) }
    else node
    end
  end

  let(:part_md) { "# Intro heading\n\nSome paragraph text.\n\n- alpha\n- beta\n" }
  # The adoc-authored equivalent of the markdown fragment: same heading
  # level, paragraph and unordered list.
  let(:part_adoc) { "== Intro heading\n\nSome paragraph text.\n\n* alpha\n* beta\n" }
  let(:host_adoc) { "= Mixed document\n\ninclude::part.md[]\n" }

  def with_fixtures(name)
    Dir.mktmpdir("ceradoc-mixed-#{name}-") do |dir|
      yield Pathname.new(dir)
    end
  end

  def write(dir, mapping)
    mapping.each do |rel, content|
      target = dir.join(rel)
      target.dirname.mkpath
      target.write(content)
    end
  end

  def parse_adoc(text)
    Ceradoc.parse(text, format: :asciidoc)
  end

  def parse_md(text)
    Ceradoc.parse(text, format: :markdown)
  end

  def all_nodes(core)
    found = []
    walker = lambda { |node|
      found << node
      next unless node.is_a?(Ceradoc::CoreModel::Base)

      Array(node.children).each { |c| walker.call(c) } if node.respond_to?(:children)
      Array(node.items).each { |c| walker.call(c) } if node.is_a?(Ceradoc::CoreModel::ListBlock)
    }
    walker.call(core)
    found
  end

  def include_nodes(core)
    all_nodes(core).grep(Ceradoc::CoreModel::Include)
  end

  def body_text(core)
    all_nodes(core).select { |n| n.is_a?(Ceradoc::CoreModel::TextContent) }
                   .map(&:text).join
  end

  # ── Extension-to-format dispatch ──

  describe 'extension-to-format dispatch' do
    it 'splices a .md target inside an .adoc tree as markdown' do
      with_fixtures('md_into_adoc') do |dir|
        write(dir, 'host.adoc' => host_adoc, 'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s)

        # The md heading arrives as a markdown-lifted SectionElement —
        # NOT an adoc paragraph carrying the raw "# " text.
        types = resolved.children.map(&:class)
        expect(types).to include(Ceradoc::CoreModel::SectionElement)
        expect(body_text(resolved)).not_to include('# Intro heading')
        expect(body_text(resolved)).to include('Some paragraph text.alpha')
      end
    end

    it 'splices an .adoc target inside a markdown host tree as asciidoc' do
      with_fixtures('adoc_into_md') do |dir|
        write(dir, 'frag.adoc' => part_adoc)

        # Markdown lift does not produce Include nodes from md syntax,
        # so the reverse direction is exercised on a constructed host
        # tree: the resolver is format-agnostic over CoreModel.
        host = Ceradoc::CoreModel::DocumentElement.new(
          children: [Ceradoc::CoreModel::Include.new(target: 'frag.adoc')]
        )
        resolved = Ceradoc.resolve_includes(host, base_dir: dir.to_s)

        section = resolved.children.first
        expect(section).to be_a(Ceradoc::CoreModel::SectionElement)
        # adoc lift fingerprints the markdown lift never produces:
        # section ids and paragraph source lines.
        expect(section.id).to eq('_intro_heading')
        paragraphs = all_nodes(resolved).grep(Ceradoc::CoreModel::ParagraphBlock)
        expect(paragraphs).not_to be_empty
        expect(paragraphs.first.lines).to eq(['Some paragraph text.'])
      end
    end

    it 'keeps dispatching through nested adoc chains into markdown leaves' do
      with_fixtures('nested_mixed') do |dir|
        write(dir, 'host.adoc' => "= Top\n\ninclude::mid.adoc[]\n",
                   'mid.adoc' => "== Mid\n\ninclude::leaf.md[]\n",
                   'leaf.md' => "# Leaf heading\n\nLeaf body.\n")

        core = parse_adoc(dir.join('host.adoc').read)
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(resolved)).to include('Leaf body.')
        sections = all_nodes(resolved).grep(Ceradoc::CoreModel::SectionElement)
        expect(sections.map(&:title)).to include('Mid', 'Leaf heading')
      end
    end
  end

  # ── INC diagnostics ──

  describe 'INC diagnostics on the #377 currency' do
    it 'emits INC001 with the including file and directive line for a missing target' do
      with_fixtures('inc001_missing') do |dir|
        write(dir, 'host.adoc' => "= Doc\n\nintro\n\ninclude::missing.md[]\n\nafter\n",
                   'mid.adoc' => '')

        core = parse_adoc(dir.join('host.adoc').read)
        directive_line = include_nodes(core).first.source_line
        diagnostics = []

        Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                       missing_include: :warn,
                                       source_path: dir.join('host.adoc').to_s,
                                       diagnostics: diagnostics)

        expect(diagnostics.size).to eq(1)
        diagnostic = diagnostics.first
        expect(diagnostic).to be_a(Ceradoc::Lint::Diagnostic)
        expect(diagnostic.code).to eq('INC001')
        expect(diagnostic.anchor).to eq(dir.join('host.adoc').to_s)
        expect(diagnostic.line).to eq(directive_line)
        expect(diagnostic.severity).to eq('warning')
      end
    end

    it 'anchors nested INC001 diagnostics at the file holding the directive' do
      with_fixtures('inc001_nested_anchor') do |dir|
        write(dir, 'host.adoc' => "= Doc\n\ninclude::mid.adoc[]\n",
                   'mid.adoc' => "== Mid\n\ninclude::missing.md[]\n")

        core = parse_adoc(dir.join('host.adoc').read)
        mid_core = parse_adoc(dir.join('mid.adoc').read)
        directive_line = include_nodes(mid_core).first.source_line
        diagnostics = []

        Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                       missing_include: :warn,
                                       source_path: dir.join('host.adoc').to_s,
                                       diagnostics: diagnostics)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.code).to eq('INC001')
        expect(diagnostics.first.anchor).to eq(dir.join('mid.adoc').to_s)
        expect(diagnostics.first.line).to eq(directive_line)
      end
    end

    it 'keeps the INC001 finding readable from the rescue when the policy raises' do
      with_fixtures('inc001_error_policy') do |dir|
        write(dir, 'host.adoc' => "include::missing.adoc[]\n")

        core = parse_adoc(dir.join('host.adoc').read)
        diagnostics = []

        expect do
          Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                         source_path: dir.join('host.adoc').to_s,
                                         diagnostics: diagnostics)
        end.to raise_error(Ceradoc::IncludeNotFoundError)

        expect(diagnostics.map(&:code)).to eq(%w[INC001])
        expect(diagnostics.first.severity).to eq('error')
      end
    end

    it 'emits INC002 before raising on a cycle' do
      with_fixtures('inc002_cycle') do |dir|
        write(dir, 'a.adoc' => "include::b.adoc[]\n",
                   'b.adoc' => "include::a.adoc[]\n")

        core = parse_adoc(dir.join('a.adoc').read)
        diagnostics = []

        expect do
          Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                         source_path: dir.join('a.adoc').to_s,
                                         diagnostics: diagnostics)
        end.to raise_error(Ceradoc::CircularIncludeError)

        expect(diagnostics.map(&:code)).to eq(%w[INC002])
        expect(diagnostics.first.anchor).to eq(dir.join('b.adoc').to_s)
      end
    end

    it 'emits INC003 for a target outside the include_formats allowlist and keeps the directive' do
      with_fixtures('inc003_allowlist') do |dir|
        write(dir, 'host.adoc' => "= Doc\n\ninclude::part.md[]\n",
                   'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        diagnostics = []
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                                  include_formats: %i[asciidoc],
                                                  source_path: dir.join('host.adoc').to_s,
                                                  diagnostics: diagnostics)

        expect(diagnostics.map(&:code)).to eq(%w[INC003])
        expect(diagnostics.first.message).to include(':markdown')
        # Policy-blocked content is NOT spliced; the directive survives.
        expect(include_nodes(resolved).map(&:target)).to eq(['part.md'])
        expect(body_text(resolved)).not_to include('Some paragraph text.')
      end
    end

    it 'stays silent on INC003 without an allowlist and resolves the same target' do
      with_fixtures('inc003_silent') do |dir|
        write(dir, 'host.adoc' => "= Doc\n\ninclude::part.md[]\n",
                   'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        diagnostics = []
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                                  source_path: dir.join('host.adoc').to_s,
                                                  diagnostics: diagnostics)

        expect(diagnostics).to be_empty
        expect(include_nodes(resolved)).to be_empty
        expect(body_text(resolved)).to include('Some paragraph text.')
      end
    end

    it 'emits INC001 and falls back to the host format for an unknown extension' do
      with_fixtures('inc001_unknown_ext') do |dir|
        write(dir, 'host.adoc' => "= Doc\n\ninclude::notes.xyz[]\n",
                   'notes.xyz' => "plain text line\n")

        core = parse_adoc(dir.join('host.adoc').read)
        diagnostics = []
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s,
                                                  source_path: dir.join('host.adoc').to_s,
                                                  diagnostics: diagnostics)

        expect(diagnostics.map(&:code)).to eq(%w[INC001])
        expect(diagnostics.first.severity).to eq('warning')
        expect(diagnostics.first.message).to include('notes.xyz')
        # Backward-compatible: the content still splices under the host
        # format, exactly as before the dispatch existed.
        expect(body_text(resolved)).to include('plain text line')
      end
    end

    it 'exposes the INC rule family through the lint registry' do
      ids = Ceradoc::Lint.registry.for_format(:include).map(&:id)
      expect(ids).to contain_exactly('INC001', 'INC002', 'INC003')
    end
  end

  # ── Include preservation on write-back ──

  describe 'include preservation on write-back' do
    it 'serializes each FILE in its own format; the host keeps the include edge' do
      with_fixtures('write_back') do |dir|
        write(dir, 'host.adoc' => "= Mixed document\n\ninclude::part.md[]\n\nTrailing host text.\n",
                   'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s)

        # Host write-back: the include directive line survives and the
        # spliced md content is NOT inlined into the host text.
        host_text = Ceradoc.serialize(core, to: :asciidoc)
        expect(host_text).to include('include::part.md[]')
        expect(host_text).to include('Trailing host text.')
        expect(host_text).not_to include('Some paragraph text')

        # Part write-back: markdown writes as markdown.
        part_core = parse_md(dir.join('part.md').read)
        part_text = Ceradoc.serialize(part_core, to: :markdown)
        expect(part_text).to include('Intro heading')
        expect(part_text).to include('Some paragraph text.')

        # The resolved tree is a view: its Include edges are spent, so
        # serializing IT inlines the md content instead of the edge.
        expect(include_nodes(resolved)).to be_empty
        expect(Ceradoc.serialize(resolved, to: :asciidoc)).to include('Some paragraph text')
      end
    end

    it 'does not mutate the parsed mixed tree during resolution' do
      with_fixtures('mixed_immutability') do |dir|
        write(dir, 'host.adoc' => host_adoc, 'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        expect { Ceradoc.resolve_includes(core, base_dir: dir.to_s) }
          .not_to(change { include_nodes(core).map(&:target) })
      end
    end
  end

  # ── CoreModel differential ──

  describe 'CoreModel differential: md splice vs native parse vs adoc equivalent' do
    it 'splices exactly the CoreModel a native markdown parse produces' do
      with_fixtures('differential') do |dir|
        write(dir, 'host.adoc' => host_adoc, 'part.md' => part_md)

        core = parse_adoc(dir.join('host.adoc').read)
        resolved = Ceradoc.resolve_includes(core, base_dir: dir.to_s)
        native = parse_md(part_md)

        # children[0] is the host's doctitle HeaderElement; the splice
        # segment that follows must equal the native md tree, node for
        # node, at CoreModel level.
        spliced = resolved.children.drop(1)
        expect(projection_of(spliced)).to eq(projection_of(native.children))
      end
    end

    it 'produces identical CoreModel for the list construct across both formats' do
      md_list = projection_of(all_nodes(parse_md(part_md)).grep(Ceradoc::CoreModel::ListBlock).first)
      adoc_list = projection_of(all_nodes(parse_adoc(part_adoc)).grep(Ceradoc::CoreModel::ListBlock).first)

      expect(md_list).to eq(adoc_list)
    end

    it 'carries the same text flow as the adoc-authored equivalent' do
      with_fixtures('text_flow') do |dir|
        write(dir, 'host.adoc' => host_adoc, 'part.md' => part_md)

        resolved = Ceradoc.resolve_includes(parse_adoc(dir.join('host.adoc').read),
                                            base_dir: dir.to_s)
        authored = parse_adoc("= Mixed document\n\n#{part_adoc}")

        expect(body_text(resolved)).to eq(body_text(authored))
      end
    end
  end
end
