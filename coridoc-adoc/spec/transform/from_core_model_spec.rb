# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::FromCoreModel do
  let(:transformer) { described_class.new }

  describe '#transform' do
    context 'when transforming a document' do
      it 'transforms a CoreModel document to AsciiDoc' do
        doc = Coridoc::CoreModel::DocumentElement.new(
          title: 'Test Document',
          children: []
        )

        result = transformer.transform(doc)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Document)
        expect(result.header.title.content).to eq('Test Document')
      end
    end

    context 'when transforming a section' do
      it 'transforms a CoreModel section to AsciiDoc' do
        section = Coridoc::CoreModel::SectionElement.new(
          id: 'intro',
          level: 2,
          title: 'Introduction',
          children: []
        )

        result = transformer.transform(section)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Section)
        expect(result.id).to eq('intro')
        expect(result.level).to eq(2)
        expect(result.title.content).to eq('Introduction')
      end
    end

    context 'when transforming a block' do
      it 'transforms a CoreModel example block to AsciiDoc' do
        block = Coridoc::CoreModel::Block.new(
          id: 'example-1',
          block_semantic_type: :example,
          delimiter_type: '====',
          content: "Line 1\nLine 2"
        )

        result = transformer.transform(block)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Block::Example)
        expect(result.id).to eq('example-1')
      end
    end

    context 'when transforming a list' do
      it 'transforms a CoreModel list to AsciiDoc' do
        items = [
          Coridoc::CoreModel::ListItem.new(marker: '*', content: 'Item 1'),
          Coridoc::CoreModel::ListItem.new(marker: '*', content: 'Item 2')
        ]
        list = Coridoc::CoreModel::ListBlock.new(
          marker_type: 'asterisk',
          items: items
        )

        result = transformer.transform(list)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::List::Unordered)
        expect(result.items.count).to eq(2)
      end
    end

    context 'when transforming a table' do
      it 'transforms a CoreModel table to AsciiDoc' do
        rows = [
          Coridoc::CoreModel::TableRow.new(
            cells: [
              Coridoc::CoreModel::TableCell.new(content: 'Cell 1'),
              Coridoc::CoreModel::TableCell.new(content: 'Cell 2')
            ]
          )
        ]
        table = Coridoc::CoreModel::Table.new(rows: rows)

        result = transformer.transform(table)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Table)
        expect(result.rows.count).to eq(1)
      end
    end

    context 'when transforming an image' do
      it 'transforms a CoreModel block image to AsciiDoc BlockImage' do
        image = Coridoc::CoreModel::Image.new(
          src: 'diagram.png',
          alt: 'System Diagram'
        )

        result = transformer.transform(image)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Image::BlockImage)
        expect(result.path).to eq('diagram.png')
        expect(result.alt).to eq('System Diagram')
      end

      it 'promotes typed fields (width, height, link, role) onto the result' do
        image = Coridoc::CoreModel::Image.new(
          src: 'diagram.png',
          alt: 'System Diagram',
          width: '800',
          height: '600',
          link: 'https://example.org',
          role: 'figure'
        )

        result = transformer.transform(image)

        expect(result.width).to eq('800')
        expect(result.height).to eq('600')
        expect(result.link).to eq('https://example.org')
        expect(result.role).to eq('figure')
      end

      it 'produces an InlineImage when CoreModel image is inline' do
        image = Coridoc::CoreModel::Image.new(
          src: 'icon.png',
          alt: 'Icon',
          inline: true
        )

        result = transformer.transform(image)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Image::InlineImage)
      end
    end

    context 'when transforming an annotation' do
      it 'transforms a CoreModel annotation to AsciiDoc admonition' do
        annotation = Coridoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'note',
          content: 'This is important'
        )

        result = transformer.transform(annotation)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Admonition)
        expect(result.type).to eq('NOTE')
      end

      it 'distinguishes AnnotationBlock from Block (AnnotationBlock < Block)' do
        annotation = Coridoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'warning',
          content: 'Danger'
        )

        result = transformer.transform(annotation)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Admonition)
        expect(result.type).to eq('WARNING')
      end
    end

    context 'when transforming inline elements' do
      it 'transforms bold to Inline::Bold' do
        inline = Coridoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold text')

        result = transformer.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Bold)
      end

      it 'transforms italic to Inline::Italic' do
        inline = Coridoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic text')

        result = transformer.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Italic)
      end

      it 'transforms monospace to Inline::Monospace' do
        inline = Coridoc::CoreModel::InlineElement.new(format_type: 'monospace', content: 'code')

        result = transformer.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Monospace)
      end

      it 'transforms link to Inline::CrossReference for xref' do
        inline = Coridoc::CoreModel::InlineElement.new(
          format_type: 'xref', content: 'Section', target: 'section_1'
        )

        result = transformer.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::CrossReference)
      end

      it 'transforms RawInlineElement to Inline::Passthrough' do
        raw = Coridoc::CoreModel::RawInlineElement.new(content: '<abbr>WYSIWYM</abbr>')

        result = transformer.transform(raw)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Passthrough)
        expect(result.content).to eq('<abbr>WYSIWYM</abbr>')
      end
    end

    context 'when transforming a footnote' do
      it 'transforms a CoreModel footnote to AsciiDoc' do
        footnote = Coridoc::CoreModel::Footnote.new(id: '1', content: 'A footnote')

        result = transformer.transform(footnote)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Footnote)
      end
    end

    context 'when transforming a definition list' do
      it 'transforms a CoreModel definition list to AsciiDoc' do
        dl = Coridoc::CoreModel::DefinitionList.new(
          items: [
            Coridoc::CoreModel::DefinitionItem.new(term: 'Term 1', definitions: ['Definition 1'])
          ]
        )

        result = transformer.transform(dl)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::List::Definition)
        expect(result.items.count).to eq(1)
      end
    end

    context 'when transforming an array' do
      it 'transforms each element in the collection' do
        elements = [
          Coridoc::CoreModel::SectionElement.new(
            level: 1,
            title: 'Section 1'
          ),
          Coridoc::CoreModel::SectionElement.new(
            level: 1,
            title: 'Section 2'
          )
        ]

        result = transformer.transform(elements)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coridoc::AsciiDoc::Model::Section)
      end
    end
  end
end
