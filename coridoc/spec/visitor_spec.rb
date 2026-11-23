# frozen_string_literal: true

require 'spec_helper'
require 'coridoc/visitor'

RSpec.describe Coridoc::Visitor do
  let(:document) do
    Coridoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      title: 'Test Document',
      children: [
        Coridoc::CoreModel::ParagraphBlock.new(
          content: 'First paragraph'
        ),
        Coridoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Section 1',
          children: [
            Coridoc::CoreModel::ParagraphBlock.new(
              content: 'Second paragraph'
            )
          ]
        ),
        Coridoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coridoc::CoreModel::ListItem.new(content: 'Item 1'),
            Coridoc::CoreModel::ListItem.new(content: 'Item 2')
          ]
        )
      ]
    )
  end

  describe Coridoc::Visitor::Base do
    subject { described_class.new }

    describe '#visit' do
      it 'visits structural elements' do
        expect { subject.visit(document) }.not_to raise_error
      end

      it 'visits blocks' do
        block = Coridoc::CoreModel::ParagraphBlock.new(content: 'Test')
        expect { subject.visit(block) }.not_to raise_error
      end

      it 'visits list blocks' do
        list = Coridoc::CoreModel::ListBlock.new(marker_type: 'unordered')
        expect { subject.visit(list) }.not_to raise_error
      end

      it 'visits nil without error' do
        expect { subject.visit(nil) }.not_to raise_error
      end

      it 'visits arrays' do
        arr = [document, Coridoc::CoreModel::Block.new(block_semantic_type: 'test')]
        expect { subject.visit(arr) }.not_to raise_error
      end
    end
  end

  describe Coridoc::Visitor::Collector do
    describe '#visit' do
      it 'collects all elements when no types specified' do
        collector = described_class.new
        document.accept(collector)

        expect(collector.items.length).to be > 0
        expect(collector.items).to include(document)
      end

      it 'collects only specified types' do
        collector = described_class.new(Coridoc::CoreModel::Block)
        document.accept(collector)

        expect(collector.items).to all(be_a(Coridoc::CoreModel::Block))
      end

      it 'collects multiple types' do
        collector = described_class.new(
          Coridoc::CoreModel::Block,
          Coridoc::CoreModel::ListBlock
        )
        document.accept(collector)

        expect(collector.items).to all(be_a(Coridoc::CoreModel::Block).or(be_a(Coridoc::CoreModel::ListBlock)))
      end
    end

    describe '#match?' do
      it 'returns true for all when no types specified' do
        collector = described_class.new
        expect(collector.match?(document)).to be true
        expect(collector.match?(Coridoc::CoreModel::Block.new)).to be true
      end

      it 'returns true for matching types' do
        collector = described_class.new(Coridoc::CoreModel::Block)
        expect(collector.match?(Coridoc::CoreModel::Block.new)).to be true
        expect(collector.match?(Coridoc::CoreModel::ListBlock.new)).to be false
      end
    end
  end

  describe Coridoc::Visitor::Transformer do
    describe '#visit' do
      it 'transforms elements using the block' do
        transformed = []
        transformer = described_class.new do |element|
          transformed << element.class
        end

        document.accept(transformer)

        expect(transformed).to include(Coridoc::CoreModel::StructuralElement)
        expect(transformed).to include(Coridoc::CoreModel::ParagraphBlock)
      end

      it 'can modify elements' do
        transformer = described_class.new do |element|
          element.content = element.content.upcase if element.is_a?(Coridoc::CoreModel::Block) && element.content.is_a?(String)
        end

        document.accept(transformer)

        paragraphs = document.children.select { |c| c.is_a?(Coridoc::CoreModel::Block) }
        first_paragraph = paragraphs.first
        expect(first_paragraph.content).to eq('FIRST PARAGRAPH')
      end
    end
  end

  describe Coridoc::Visitor::Finder do
    describe '#visit' do
      it 'finds elements matching predicate' do
        finder = described_class.new { |e| e.is_a?(Coridoc::CoreModel::Block) }
        document.accept(finder)

        expect(finder.results).to all(be_a(Coridoc::CoreModel::Block))
      end

      it 'finds elements by id' do
        block_with_id = Coridoc::CoreModel::ParagraphBlock.new(
          content: 'Test',
          id: 'my-block'
        )
        doc = Coridoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          children: [block_with_id]
        )

        finder = described_class.new { |e| e.id == 'my-block' }
        doc.accept(finder)

        expect(finder.first).to eq(block_with_id)
      end
    end

    describe '#first' do
      it 'returns first matching result' do
        finder = described_class.new { |e| e.is_a?(Coridoc::CoreModel::ListItem) }
        document.accept(finder)

        expect(finder.first).to be_a(Coridoc::CoreModel::ListItem)
      end

      it 'returns nil when no matches' do
        finder = described_class.new { |e| e.id == 'nonexistent' }
        document.accept(finder)

        expect(finder.first).to be_nil
      end
    end

    describe '#all' do
      it 'returns all matching results' do
        finder = described_class.new { |e| e.is_a?(Coridoc::CoreModel::Block) }
        document.accept(finder)

        expect(finder.all.length).to be >= 2
      end
    end
  end

  describe 'Document#accept' do
    it 'allows visitor pattern on CoreModel elements' do
      word_count = 0
      visitor = Coridoc::Visitor::Transformer.new do |element|
        word_count += element.content.split.length if element.is_a?(Coridoc::CoreModel::Block) && element.content.is_a?(String)
      end

      document.accept(visitor)

      expect(word_count).to eq(4) # "First paragraph" (2) + "Second paragraph" (2)
    end
  end

  describe 'Table visitor' do
    let(:table) do
      Coridoc::CoreModel::Table.new(
        rows: [
          Coridoc::CoreModel::TableRow.new(
            cells: [
              Coridoc::CoreModel::TableCell.new(content: 'A1'),
              Coridoc::CoreModel::TableCell.new(content: 'B1')
            ]
          ),
          Coridoc::CoreModel::TableRow.new(
            cells: [
              Coridoc::CoreModel::TableCell.new(content: 'A2'),
              Coridoc::CoreModel::TableCell.new(content: 'B2')
            ]
          )
        ]
      )
    end

    it 'visits table structure' do
      cells = []
      visitor = Coridoc::Visitor::Transformer.new do |element|
        cells << element if element.is_a?(Coridoc::CoreModel::TableCell)
      end

      table.accept(visitor)

      expect(cells.length).to eq(4)
    end
  end

  describe 'Image visitor' do
    let(:image) do
      Coridoc::CoreModel::Image.new(
        src: 'test.png',
        alt: 'Test image'
      )
    end

    it 'visits image elements' do
      visited = []
      visitor = Coridoc::Visitor::Transformer.new do |element|
        visited << element if element.is_a?(Coridoc::CoreModel::Image)
      end

      image.accept(visitor)

      expect(visited).to include(image)
    end
  end

  describe 'Annotation block visitor' do
    let(:admonition) do
      Coridoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note',
        content: 'This is a note'
      )
    end

    it 'visits annotation blocks' do
      visited = []
      visitor = Coridoc::Visitor::Transformer.new do |element|
        visited << element if element.is_a?(Coridoc::CoreModel::AnnotationBlock)
      end

      admonition.accept(visitor)

      expect(visited).to include(admonition)
    end

    it 'dispatches AnnotationBlock to visit_annotation_block, not visit_block' do
      dispatch_log = []
      visitor = Class.new(Coridoc::Visitor::Base) do
        define_method(:visit_annotation_block) do |el|
          dispatch_log << :annotation_block
          super(el)
        end
        define_method(:visit_block) do |el|
          dispatch_log << :block
          super(el)
        end
      end.new

      admonition.accept(visitor)

      expect(dispatch_log).to eq([:annotation_block])
    end

    it 'does not dispatch AnnotationBlock to visit_block' do
      block_visits = 0
      visitor = Class.new(Coridoc::Visitor::Base) do
        define_method(:visit_block) do |el|
          block_visits += 1
          super(el)
        end
      end.new

      admonition.accept(visitor)

      expect(block_visits).to eq(0)
    end
  end

  describe 'dispatch for all CoreModel types' do
    def dispatches_to?(element, expected_method)
      log = []
      visitor = Class.new(Coridoc::Visitor::Base) do
        define_method(expected_method) do |el|
          log << expected_method
          super(el)
        end
      end.new
      element.accept(visitor)
      log == [expected_method]
    end

    it 'dispatches Footnote to visit_footnote' do
      footnote = Coridoc::CoreModel::Footnote.new(content: 'A footnote')
      expect(dispatches_to?(footnote, :visit_footnote)).to be true
    end

    it 'dispatches FootnoteReference to visit_footnote_reference' do
      ref = Coridoc::CoreModel::FootnoteReference.new(target: 'fn1')
      expect(dispatches_to?(ref, :visit_footnote_reference)).to be true
    end

    it 'dispatches DefinitionList to visit_definition_list' do
      dl = Coridoc::CoreModel::DefinitionList.new(
        items: [Coridoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])]
      )
      expect(dispatches_to?(dl, :visit_definition_list)).to be true
    end

    it 'dispatches DefinitionItem to visit_definition_item' do
      di = Coridoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])
      expect(dispatches_to?(di, :visit_definition_item)).to be true
    end

    it 'dispatches Bibliography to visit_bibliography' do
      bib = Coridoc::CoreModel::Bibliography.new
      expect(dispatches_to?(bib, :visit_bibliography)).to be true
    end

    it 'dispatches BibliographyEntry to visit_bibliography_entry' do
      entry = Coridoc::CoreModel::BibliographyEntry.new(ref: 'ISO123')
      expect(dispatches_to?(entry, :visit_bibliography_entry)).to be true
    end

    it 'dispatches Toc to visit_toc' do
      toc = Coridoc::CoreModel::Toc.new
      expect(dispatches_to?(toc, :visit_toc)).to be true
    end

    it 'dispatches TocEntry to visit_toc_entry' do
      entry = Coridoc::CoreModel::TocEntry.new(title: 'Section 1')
      expect(dispatches_to?(entry, :visit_toc_entry)).to be true
    end

    it 'visits bibliography entries' do
      entry1 = Coridoc::CoreModel::BibliographyEntry.new(ref: 'ISO1')
      entry2 = Coridoc::CoreModel::BibliographyEntry.new(ref: 'ISO2')
      bib = Coridoc::CoreModel::Bibliography.new(entries: [entry1, entry2])
      visitor = Coridoc::Visitor::Collector.new(Coridoc::CoreModel::BibliographyEntry)
      bib.accept(visitor)

      expect(visitor.items).to contain_exactly(entry1, entry2)
    end

    it 'visits definition list items' do
      item1 = Coridoc::CoreModel::DefinitionItem.new(term: 'A')
      item2 = Coridoc::CoreModel::DefinitionItem.new(term: 'B')
      dl = Coridoc::CoreModel::DefinitionList.new(items: [item1, item2])

      visitor = Coridoc::Visitor::Collector.new(Coridoc::CoreModel::DefinitionItem)
      dl.accept(visitor)

      expect(visitor.items).to contain_exactly(item1, item2)
    end

    it 'dispatches Metadata to visit_metadata' do
      meta = Coridoc::CoreModel::Metadata.new
      expect(dispatches_to?(meta, :visit_metadata)).to be true
    end

    it 'dispatches MetadataEntry to visit_metadata_entry' do
      entry = Coridoc::CoreModel::MetadataEntry.new(key: 'author', value: 'Test')
      expect(dispatches_to?(entry, :visit_metadata_entry)).to be true
    end

    it 'dispatches ElementAttribute to visit_element_attribute' do
      attr = Coridoc::CoreModel::ElementAttribute.new(name: 'role', value: 'note')
      expect(dispatches_to?(attr, :visit_element_attribute)).to be true
    end

    it 'visits metadata entries' do
      entry1 = Coridoc::CoreModel::MetadataEntry.new(key: 'a', value: '1')
      entry2 = Coridoc::CoreModel::MetadataEntry.new(key: 'b', value: '2')
      meta = Coridoc::CoreModel::Metadata.new(entries: [entry1, entry2])

      visitor = Coridoc::Visitor::Collector.new(Coridoc::CoreModel::MetadataEntry)
      meta.accept(visitor)

      expect(visitor.items).to contain_exactly(entry1, entry2)
    end
  end

  describe 'DISPATCH_TABLE registry' do
    it 'maps every registered CoreModel type to a visit method' do
      Coridoc::Visitor::DISPATCH_TABLE.each do |klass, method_name|
        expect(Coridoc::Visitor::Base.instance_methods(false)).to include(method_name),
                                                                  "#{klass} maps to #{method_name}, but no such method on Base"
      end
    end

    it 'allows external registration for new types' do
      custom_class = Class.new(Coridoc::CoreModel::Base)
      described_class.register_visitor(custom_class, :visit_custom)

      visited = false
      visitor = Class.new(Coridoc::Visitor::Base) do
        define_method(:visit_custom) { |_el| visited = true }
      end.new

      instance = custom_class.new
      visitor.visit(instance)

      expect(visited).to be true

      Coridoc::Visitor::DISPATCH_TABLE.delete(custom_class)
    end

    it 'falls back to visit_unknown for unregistered types' do
      unknown = Object.new
      visited = false
      visitor = Class.new(Coridoc::Visitor::Base) do
        define_method(:visit_unknown) { |_el| visited = true }
      end.new

      visitor.visit(unknown)
      expect(visited).to be true
    end
  end
end
