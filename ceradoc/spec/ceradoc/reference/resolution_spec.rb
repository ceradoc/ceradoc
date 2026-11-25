# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc'

RSpec.describe 'Ceradoc.resolve_references (end-to-end)' do
  let(:section_a) do
    Ceradoc::CoreModel::SectionElement.new(
      id: 'sec-a', title: 'Section A', level: 1,
      children: [
        Ceradoc::CoreModel::ParagraphBlock.new(
          content: 'See ',
          children: [
            Ceradoc::CoreModel::TextElement.new(content: 'See '),
            Ceradoc::CoreModel::CrossReferenceElement.new(
              target: 'sec-b',
              id: 'xref-1',
              content: 'Section B',
              children: [
                Ceradoc::CoreModel::TextElement.new(content: 'Section B')
              ]
            )
          ]
        )
      ]
    )
  end

  let(:section_b) do
    Ceradoc::CoreModel::SectionElement.new(
      id: 'sec-b', title: 'Section B', level: 1, children: []
    )
  end

  let(:document) do
    Ceradoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc', children: [section_a, section_b]
    )
  end

  let(:catalog) { Ceradoc::Reference::Catalog::Local.from_doc(document) }
  let(:presentation) { Ceradoc::Reference::Presentation::SingleDocument.new }
  let(:empty_catalog) do
    Ceradoc::Reference::Catalog::Local.from_doc(
      Ceradoc::CoreModel::DocumentElement.new(id: 'empty', title: 'Empty', children: [])
    )
  end

  it 'does not mutate the input document' do
    original_id = document.children.first.children.first.children.last.id
    Ceradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      materialize: false
    )
    expect(document.children.first.children.first.children.last.id).to eq(original_id)
  end

  it 'returns the input document when materialize is false' do
    resolved = Ceradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation
    )
    expect(resolved).to be(document)
  end

  it 'resolves references without materializing (validation step)' do
    expect do
      Ceradoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation,
        missing: :error
      )
    end.to raise_error(Ceradoc::Reference::MissingReferenceError)
  end

  it 'warns about unresolvable references without materializing' do
    expect do
      Ceradoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation
      )
    end.to output(/sec-b/).to_stderr
  end

  context 'when materializers are registered globally (format gem extension point)' do
    def html_like_materializer
      Class.new(Ceradoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :any
        def self.format = :html

        def materialize(edge:, **)
          Ceradoc::CoreModel::LinkElement.new(
            target: "##{edge.address.target}",
            content: edge.label,
            children: [Ceradoc::CoreModel::TextElement.new(content: edge.label)]
          )
        end
      end
    end

    around do |example|
      Ceradoc::Reference::Materializer::Registry.register_global(html_like_materializer)
      example.run
    ensure
      Ceradoc::Reference::Materializer::Registry.reset_globals!
    end

    it 'returns a new document when materializing with a matching materializer' do
      resolved = Ceradoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      expect(resolved).not_to be(document)
    end

    it 'materializes the cross-reference through the globally registered materializer' do
      resolved = Ceradoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      inline = find_first(resolved) { |n| n.is_a?(Ceradoc::CoreModel::LinkElement) }
      expect(inline).not_to be_nil
      expect(inline.target).to eq('#sec-b')
    end

    it 'materializes without mutating a deep-frozen input tree' do
      deep_freeze(document)
      resolved = Ceradoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        format: :html,
        materialize: true
      )
      inline = find_first(resolved) { |n| n.is_a?(Ceradoc::CoreModel::LinkElement) }
      expect(inline).not_to be_nil
    end
  end

  it 'uses the caller-supplied resolver' do
    caching = Ceradoc::Reference::Resolver::Caching.new(
      inner: Ceradoc::Reference::Resolver::Catalog.new(catalog: catalog)
    )
    Ceradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      resolver: caching
    )
    expect(caching.size).to eq(1)
  end

  it 'warns about unresolvable references when materializing with missing: :warn' do
    expect do
      Ceradoc.resolve_references(
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
      Ceradoc.resolve_references(
        document,
        catalog: empty_catalog,
        presentation: presentation,
        missing: :error,
        materialize: true
      )
    end.to raise_error(Ceradoc::Reference::MissingReferenceError)
  end

  it 'preserves nodes whose kind has no registered materializer when materialize: true' do
    doc = Ceradoc::CoreModel::DocumentElement.new(
      id: 'imgdoc', title: 'ImgDoc',
      children: [
        Ceradoc::CoreModel::ParagraphBlock.new(
          content: 'pic',
          children: [
            Ceradoc::CoreModel::Image.new(src: 'images/pic.png', alt: 'My Alt', id: 'img-1')
          ]
        )
      ]
    )
    resolved = Ceradoc.resolve_references(
      doc,
      catalog: Ceradoc::Reference::Catalog::Local.from_doc(doc),
      presentation: presentation,
      materialize: true
    )
    image = find_first(resolved) { |n| n.is_a?(Ceradoc::CoreModel::Image) }
    expect(image).not_to be_nil
    expect(image.alt).to eq('My Alt')
    flattened = find_first(resolved) do |n|
      n.is_a?(Ceradoc::CoreModel::TextElement) && n.content == 'My Alt'
    end
    expect(flattened).to be_nil
  end

  it 'drops an unresolved xref that is the last child when missing: :silent' do
    doc = Ceradoc::CoreModel::DocumentElement.new(
      id: 'doc2', title: 'Doc2',
      children: [
        Ceradoc::CoreModel::ParagraphBlock.new(
          content: 'See ',
          children: [
            Ceradoc::CoreModel::TextElement.new(content: 'See '),
            Ceradoc::CoreModel::CrossReferenceElement.new(
              target: 'nope', id: 'x1',
              children: [Ceradoc::CoreModel::TextElement.new(content: 'nope')]
            )
          ]
        )
      ]
    )
    resolved = Ceradoc.resolve_references(
      doc,
      catalog: empty_catalog,
      presentation: presentation,
      missing: :silent,
      materialize: true
    )
    xref = find_first(resolved) { |n| n.is_a?(Ceradoc::CoreModel::CrossReferenceElement) }
    expect(xref).to be_nil
  end

  context 'when selecting materializers by lookup axes' do
    def asciidoc_materializer
      Class.new(Ceradoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :any
        def self.format = :asciidoc

        def materialize(edge:, **)
          Ceradoc::CoreModel::TextElement.new(content: "ADOC:#{edge.address}")
        end
      end
    end

    def split_materializer
      Class.new(Ceradoc::Reference::Materializer::Base) do
        def self.kind = :navigation
        def self.presentation = :split_pages
        def self.format = :any

        def materialize(**)
          Ceradoc::CoreModel::TextElement.new(content: 'SPLIT')
        end
      end
    end

    def resolution_for(registry:, presentation:, format:)
      Ceradoc::Reference::Resolution.new(
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
        n.is_a?(Ceradoc::CoreModel::TextElement) && n.content.to_s.start_with?(prefix)
      end
    end

    it 'uses the materializer registered for the requested format' do
      registry = Ceradoc::Reference::Materializer::Registry.new
      registry.register(asciidoc_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :asciidoc
      ).call(document)
      expect(marker_in(resolved, 'ADOC:')).not_to be_nil
    end

    it 'ignores materializers registered for a different format' do
      registry = Ceradoc::Reference::Materializer::Registry.new
      registry.register(asciidoc_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :html
      ).call(document)
      expect(marker_in(resolved, 'ADOC:')).to be_nil
    end

    it 'uses the materializer registered for the active presentation' do
      registry = Ceradoc::Reference::Materializer::Registry.new
      registry.register(split_materializer)
      resolved = resolution_for(
        registry: registry,
        presentation: Ceradoc::Reference::Presentation::SplitPages.new,
        format: :html
      ).call(document)
      expect(marker_in(resolved, 'SPLIT')).not_to be_nil
    end

    it 'ignores materializers registered for a different presentation' do
      registry = Ceradoc::Reference::Materializer::Registry.new
      registry.register(split_materializer)
      resolved = resolution_for(
        registry: registry, presentation: presentation, format: :html
      ).call(document)
      expect(marker_in(resolved, 'SPLIT')).to be_nil
    end
  end

  def find_first(node, &block)
    return node if yield(node)

    if node.is_a?(Ceradoc::CoreModel::HasChildren) && node.children
      node.children.each do |c|
        found = find_first(c, &block)
        return found if found
      end
    end
    nil
  end

  def deep_freeze(node)
    if node.is_a?(Ceradoc::CoreModel::HasChildren) && node.children.is_a?(Array)
      node.children.each { |child| deep_freeze(child) }
      node.children.freeze
    end
    node.freeze
  end
end
