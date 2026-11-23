# frozen_string_literal: true

require 'spec_helper'
require 'coridoc'

RSpec.describe 'Coridoc.resolve_references (end-to-end)' do
  let(:section_a) do
    Coridoc::CoreModel::SectionElement.new(
      id: 'sec-a', title: 'Section A', level: 1,
      children: [
        Coridoc::CoreModel::ParagraphBlock.new(
          content: 'See ',
          children: [
            Coridoc::CoreModel::TextElement.new(content: 'See '),
            Coridoc::CoreModel::CrossReferenceElement.new(
              target: 'sec-b',
              id: 'xref-1',
              content: 'Section B',
              children: [
                Coridoc::CoreModel::TextElement.new(content: 'Section B')
              ]
            )
          ]
        )
      ]
    )
  end

  let(:section_b) do
    Coridoc::CoreModel::SectionElement.new(
      id: 'sec-b', title: 'Section B', level: 1, children: []
    )
  end

  let(:document) do
    Coridoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc', children: [section_a, section_b]
    )
  end

  let(:catalog) { Coridoc::Reference::Catalog::Local.from_doc(document) }
  let(:presentation) { Coridoc::Reference::Presentation::SingleDocument.new }
  let(:empty_catalog) do
    Coridoc::Reference::Catalog::Local.from_doc(
      Coridoc::CoreModel::DocumentElement.new(id: 'empty', title: 'Empty', children: [])
    )
  end

  it 'does not mutate the input document' do
    original_id = document.children.first.children.first.children.last.id
    Coridoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      materialize: false
    )
    expect(document.children.first.children.first.children.last.id).to eq(original_id)
  end

  it 'returns the input document when materialize is false' do
    resolved = Coridoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation
    )
    expect(resolved).to be(document)
  end

  it 'resolves references without materializing (validation step)' do
    expect do
      Coridoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation,
        missing: :error
      )
    end.to raise_error(Coridoc::Reference::MissingReferenceError)
  end

  it 'warns about unresolvable references without materializing' do
    expect do
      Coridoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation
      )
    end.to output(/sec-b/).to_stderr
  end

  context 'when materializers are registered globally (format gem extension point)' do
    def html_like_materializer
      Class.new(Coridoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :any
        def self.format = :html

        def materialize(edge:, **)
          Coridoc::CoreModel::LinkElement.new(
            target: "##{edge.address.target}",
            content: edge.label,
            children: [Coridoc::CoreModel::TextElement.new(content: edge.label)]
          )
        end
      end
    end

    around do |example|
      Coridoc::Reference::Materializer::Registry.register_global(html_like_materializer)
      example.run
    ensure
      Coridoc::Reference::Materializer::Registry.reset_globals!
    end

    it 'returns a new document when materializing with a matching materializer' do
      resolved = Coridoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      expect(resolved).not_to be(document)
    end

    it 'materializes the cross-reference through the globally registered materializer' do
      resolved = Coridoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      inline = find_first(resolved) { |n| n.is_a?(Coridoc::CoreModel::LinkElement) }
      expect(inline).not_to be_nil
      expect(inline.target).to eq('#sec-b')
    end

    it 'materializes without mutating a deep-frozen input tree' do
      deep_freeze(document)
      resolved = Coridoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      inline = find_first(resolved) { |n| n.is_a?(Coridoc::CoreModel::LinkElement) }
      expect(inline).not_to be_nil
    end
  end

  it 'uses the caller-supplied resolver' do
    caching = Coridoc::Reference::Resolver::Caching.new(
      inner: Coridoc::Reference::Resolver::Catalog.new(catalog: catalog)
    )
    Coridoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      resolver: caching
    )
    expect(caching.size).to eq(1)
  end

  it 'warns about unresolvable references when materializing with missing: :warn' do
    expect do
      Coridoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation,
        missing: :warn,
        format: :html,
        materialize: true
      )
    end.to output(/sec-b/).to_stderr
  end

  it 'raises when missing: :error' do
    expect do
      Coridoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation,
        missing: :error,
        materialize: true
      )
    end.to raise_error(Coridoc::Reference::MissingReferenceError)
  end

  it 'preserves nodes whose kind has no registered materializer when materialize: true' do
    doc = Coridoc::CoreModel::DocumentElement.new(
      id: 'imgdoc', title: 'ImgDoc',
      children: [
        Coridoc::CoreModel::ParagraphBlock.new(
          content: 'pic',
          children: [
            Coridoc::CoreModel::Image.new(src: 'images/pic.png', alt: 'My Alt', id: 'img-1')
          ]
        )
      ]
    )
    resolved = Coridoc.resolve_references(
      doc,
      catalog: Coridoc::Reference::Catalog::Local.from_doc(doc),
      presentation: presentation,
      materialize: true
    )
    image = find_first(resolved) { |n| n.is_a?(Coridoc::CoreModel::Image) }
    expect(image).not_to be_nil
    expect(image.alt).to eq('My Alt')
    flattened = find_first(resolved) do |n|
      n.is_a?(Coridoc::CoreModel::TextElement) && n.content == 'My Alt'
    end
    expect(flattened).to be_nil
  end

  it 'drops an unresolved xref that is the last child when missing: :silent' do
    doc = Coridoc::CoreModel::DocumentElement.new(
      id: 'doc2', title: 'Doc2',
      children: [
        Coridoc::CoreModel::ParagraphBlock.new(
          content: 'See ',
          children: [
            Coridoc::CoreModel::TextElement.new(content: 'See '),
            Coridoc::CoreModel::CrossReferenceElement.new(
              target: 'nope', id: 'x1',
              children: [Coridoc::CoreModel::TextElement.new(content: 'nope')]
            )
          ]
        )
      ]
    )
    resolved = Coridoc.resolve_references(
      doc,
      catalog: empty_catalog,
      presentation: presentation,
      missing: :silent,
      materialize: true
    )
    xref = find_first(resolved) { |n| n.is_a?(Coridoc::CoreModel::CrossReferenceElement) }
    expect(xref).to be_nil
  end

  context 'when selecting materializers by lookup axes' do
    def asciidoc_materializer
      Class.new(Coridoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :any
        def self.format = :asciidoc

        def materialize(edge:, **)
          Coridoc::CoreModel::TextElement.new(content: "ADOC:#{edge.address}")
        end
      end
    end

    def split_materializer
      Class.new(Coridoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :split_pages
        def self.format = :any

        def materialize(**)
          Coridoc::CoreModel::TextElement.new(content: 'SPLIT')
        end
      end
    end

    def resolution_for(registry:, presentation:, format:)
      Coridoc::Reference::Resolution.new(
        catalog: catalog,
        presentation: presentation,
        missing: :warn,
        ambiguous: :disambiguate,
        materialize: true,
        format: format,
        materializer_registry: registry
      )
    end

    def marker_in(doc, prefix)
      find_first(doc) do |n|
        n.is_a?(Coridoc::CoreModel::TextElement) && n.content.to_s.start_with?(prefix)
      end
    end

    it 'uses the materializer registered for the requested format' do
      registry = Coridoc::Reference::Materializer::Registry.new
      registry.register(asciidoc_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :asciidoc
      ).call(document)
      expect(marker_in(resolved, 'ADOC:')).not_to be_nil
    end

    it 'ignores materializers registered for a different format' do
      registry = Coridoc::Reference::Materializer::Registry.new
      registry.register(asciidoc_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :html
      ).call(document)
      expect(marker_in(resolved, 'ADOC:')).to be_nil
    end

    it 'uses the materializer registered for the active presentation' do
      registry = Coridoc::Reference::Materializer::Registry.new
      registry.register(split_materializer)
      resolved = resolution_for(
        registry: registry,
        presentation: Coridoc::Reference::Presentation::SplitPages.new,
        format: :html
      ).call(document)
      expect(marker_in(resolved, 'SPLIT')).not_to be_nil
    end

    it 'ignores materializers registered for a different presentation' do
      registry = Coridoc::Reference::Materializer::Registry.new
      registry.register(split_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :html
      ).call(document)
      expect(marker_in(resolved, 'SPLIT')).to be_nil
    end
  end

  def find_first(node, &block)
    return node if yield(node)

    if node.is_a?(Coridoc::CoreModel::HasChildren) && node.children
      node.children.each do |c|
        found = find_first(c, &block)
        return found if found
      end
    end
    nil
  end

  def deep_freeze(node)
    if node.is_a?(Coridoc::CoreModel::HasChildren) && node.children.is_a?(Array)
      node.children.each { |child| deep_freeze(child) }
      node.children.freeze
    end
    node.freeze
  end
end
