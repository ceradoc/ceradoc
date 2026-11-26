# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::AsciiDoc::Transform::ElementTransformers::BlockTransformer do
  describe '.transform_paragraph' do
    it 'transforms a basic paragraph with plain text' do
      para = Ceradoc::AsciiDoc::Model::Paragraph.new(
        id: 'para-1',
        content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Hello world')]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      expect(result.id).to eq('para-1')
      expect(result.content).to eq('Hello world')
      expect(result.lines).to eq(['Hello world'])
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Ceradoc::CoreModel::TextContent)
    end

    it 'folds soft-wrapped lines into the canonical single-line partition' do
      para = Ceradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'This is line one', line_break: "\n"),
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'of a paragraph', line_break: "\n"),
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'that spans three.')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      # `content` is the rendered view — soft-wrapped lines joined with
      # spaces so they read as flowing prose.
      expect(result.content).to eq('This is line one of a paragraph that spans three.')
      # `lines` is the canonical partition: serialization is single-line,
      # so it carries the same folded text a re-parse produces instead of
      # the raw source-line split (#376).
      expect(result.lines).to eq(['This is line one of a paragraph that spans three.'])
    end

    it 'filters out LineBreak and PageBreak items from the folded text' do
      para = Ceradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Before'),
          Ceradoc::AsciiDoc::Model::LineBreak.new,
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'After')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result.lines).to eq(['BeforeAfter'])
    end

    it 'transforms a paragraph with inline elements' do
      inline_text = Ceradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
      para = Ceradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          inline_text,
          Ceradoc::AsciiDoc::Model::TextElement.new(content: ' world')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      expect(result.content).to match(/Hello\s+bold\s*world/)
      # Inline elements between two TextElements do NOT synthesize a
      # soft-break space — the visitor only inserts " " between two
      # adjacent TextElements (i.e. real source line breaks). An
      # inline element sitting between two text runs means the source
      # had them on the same line.
      expect(result.children.size).to eq(3)
      expect(result.children.find { |c| c.is_a?(Ceradoc::CoreModel::BoldElement) }).not_to be_nil
      expect(result.children.find { |c| c.is_a?(Ceradoc::CoreModel::BoldElement) }.content).to eq('bold')
    end

    it 'handles empty content' do
      para = Ceradoc::AsciiDoc::Model::Paragraph.new(content: [])

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      expect(result.content).to eq('')
      expect(result.children).to be_empty
    end
  end

  describe '.transform_source_block' do
    it 'transforms a source block with language' do
      attr_list = Ceradoc::AsciiDoc::Model::AttributeList.new(
        positional: [
          Ceradoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'source'),
          Ceradoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'ruby')
        ]
      )
      title = Ceradoc::AsciiDoc::Model::Title.new(content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Example')])
      block = Ceradoc::AsciiDoc::Model::Block::SourceCode.new(
        id: 'src-1',
        title: title,
        attributes: attr_list,
        lines: [
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'def test'),
          Ceradoc::AsciiDoc::Model::LineBreak.new,
          Ceradoc::AsciiDoc::Model::TextElement.new(content: '  true'),
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'end')
        ]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(result.id).to eq('src-1')
      expect(result.title).to eq('Example')
      expect(result.language).to eq('ruby')
      expect(result.content).to eq("def test\n  true\nend")
      expect(result.lines).to eq(['def test', '  true', 'end'])
    end

    it 'handles source block without language' do
      block = Ceradoc::AsciiDoc::Model::Block::SourceCode.new(
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'plain code')]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(result.language).to be_nil
      expect(result.content).to eq('plain code')
    end
  end

  describe '.transform_block' do
    it 'transforms a block with a string delimiter' do
      title = Ceradoc::AsciiDoc::Model::Title.new(content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Note')])
      block = Ceradoc::AsciiDoc::Model::Block::Core.new(
        id: 'blk-1',
        title: title,
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Note content')]
      )

      result = described_class.transform_block(block, '====')

      expect(result).to be_a(Ceradoc::CoreModel::Block)
      expect(result.id).to eq('blk-1')
      expect(result.title).to eq('Note')
      expect(result.content).to eq('Note content')
      expect(result.lines).to eq(['Note content'])
      expect(result.block_semantic_type).to eq('example')
      expect(result.delimiter_type).to eq('====')
    end

    it 'transforms a block with a symbol semantic type' do
      block = Ceradoc::AsciiDoc::Model::Block::Core.new(
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Sidebar content')]
      )

      result = described_class.transform_block(block, :sidebar)

      expect(result).to be_a(Ceradoc::CoreModel::Block)
      expect(result.content).to eq('Sidebar content')
      expect(result.block_semantic_type.to_s).to eq('sidebar')
      expect(result.delimiter_type).to be_nil
    end
  end

  describe '.transform_typed_block' do
    it 'transforms into a specified class with simple lines' do
      title = Ceradoc::AsciiDoc::Model::Title.new(content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Quote')])
      block = Ceradoc::AsciiDoc::Model::Block::Quote.new(
        id: 'quote-1',
        title: title,
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'To be or not to be')]
      )

      result = described_class.transform_typed_block(
        block, Ceradoc::CoreModel::QuoteBlock, { attribution: 'Shakespeare' }
      )

      expect(result).to be_a(Ceradoc::CoreModel::QuoteBlock)
      expect(result.id).to eq('quote-1')
      expect(result.title).to eq('Quote')
      expect(result.content).to eq('To be or not to be')
      expect(result.attribution).to eq('Shakespeare')
      expect(result.children).to all(be_a(Ceradoc::CoreModel::ParagraphBlock))
    end

    it 'groups consecutive soft-wrapped lines into a single paragraph' do
      block = Ceradoc::AsciiDoc::Model::Block::Example.new(
        lines: [
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 1.', line_break: "\n"),
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 2.', line_break: "\n"),
          Ceradoc::AsciiDoc::Model::LineBreak.new,
          Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Second paragraph here.')
        ]
      )

      result = described_class.transform_typed_block(
        block, Ceradoc::CoreModel::ExampleBlock
      )

      paragraphs = result.children
      expect(paragraphs.size).to eq(2)
      expect(paragraphs.all?(Ceradoc::CoreModel::ParagraphBlock)).to be(true)
      expect(paragraphs[0].content).to eq('First paragraph line 1. First paragraph line 2.')
      expect(paragraphs[1].content).to eq('Second paragraph here.')
    end

    it 'transforms into a specified class with nested blocks' do
      nested = Ceradoc::AsciiDoc::Model::Block::Core.new(
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Inner')]
      )
      block = Ceradoc::AsciiDoc::Model::Block::Example.new(
        lines: [nested]
      )

      result = described_class.transform_typed_block(
        block, Ceradoc::CoreModel::ExampleBlock
      )

      expect(result).to be_a(Ceradoc::CoreModel::ExampleBlock)
      expect(result.content).to be_nil
      expect(result.children).to be_an(Array)
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Ceradoc::CoreModel::Block)
    end

    it 'preserves inline formatting when inline prose sits alongside a nested list' do
      link = Ceradoc::AsciiDoc::Model::Inline::Link.new(
        path: 'foo.html', name: 'Simple Adoption'
      )
      text_line = Ceradoc::AsciiDoc::Model::TextElement.new(
        content: [
          'The easiest way is via ',
          link,
          '.'
        ]
      )
      list = Ceradoc::AsciiDoc::Model::List::Unordered.new(
        items: [Ceradoc::AsciiDoc::Model::List::Item.new(
          content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'item')],
          marker: '*'
        )]
      )
      block = Ceradoc::AsciiDoc::Model::Block::Example.new(lines: [text_line, list])

      result = described_class.transform_typed_block(
        block, Ceradoc::CoreModel::ExampleBlock
      )

      expect(result.children.size).to eq(2)
      expect(result.children[0]).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      expect(result.children[1]).to be_a(Ceradoc::CoreModel::ListBlock)

      paragraph = result.children[0]
      link_element = paragraph.children.find { |c| c.is_a?(Ceradoc::CoreModel::LinkElement) }
      expect(link_element).not_to be_nil
      expect(link_element.target).to eq('foo.html')
      expect(link_element.content).to eq('Simple Adoption')
    end
  end

  describe '.build_typed_block_children' do
    def build(lines)
      described_class.build_typed_block_children(lines)
    end

    it 'returns [children, content] tuple with content nil when only nested blocks' do
      nested = Ceradoc::AsciiDoc::Model::Block::Core.new(
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Inner')]
      )

      children, content = build([nested])
      expect(content).to be_nil
      expect(children.size).to eq(1)
      expect(children.first).to be_a(Ceradoc::CoreModel::Block)
    end

    it 'joins multiple paragraph texts with blank-line separator in content' do
      lines = [
        Ceradoc::AsciiDoc::Model::TextElement.new(content: 'First.'),
        Ceradoc::AsciiDoc::Model::LineBreak.new,
        Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Second.')
      ]

      children, content = build(lines)
      expect(children.size).to eq(2)
      expect(content).to eq("First.\n\nSecond.")
    end

    it 'flushes the pending paragraph when a block-level child appears mid-stream' do
      list = Ceradoc::AsciiDoc::Model::List::Unordered.new(
        items: [Ceradoc::AsciiDoc::Model::List::Item.new(
          content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'item')],
          marker: '*'
        )]
      )
      lines = [
        Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Before list.'),
        list
      ]

      children, content = build(lines)
      expect(children.map(&:class)).to eq([
                                            Ceradoc::CoreModel::ParagraphBlock,
                                            Ceradoc::CoreModel::ListBlock
                                          ])
      expect(content).to eq('Before list.')
    end
  end

  describe '.transform_admonition_block' do
    it 'builds an AnnotationBlock with annotation_type and ParagraphBlock children' do
      link = Ceradoc::AsciiDoc::Model::Inline::Link.new(
        path: 'foo.html', name: 'bar'
      )
      text_line = Ceradoc::AsciiDoc::Model::TextElement.new(
        content: ['See ', link, '.']
      )
      block = Ceradoc::AsciiDoc::Model::Block::Example.new(lines: [text_line])

      result = described_class.transform_admonition_block(block, 'note')

      expect(result).to be_a(Ceradoc::CoreModel::AnnotationBlock)
      expect(result.annotation_type).to eq('NOTE')
      paragraph = result.children.first
      expect(paragraph).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      link_element = paragraph.children.find { |c| c.is_a?(Ceradoc::CoreModel::LinkElement) }
      expect(link_element&.target).to eq('foo.html')
    end

    it 'canoninalises the type via AdmonitionStyles' do
      block = Ceradoc::AsciiDoc::Model::Block::Example.new(
        lines: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'body')]
      )

      result = described_class.transform_admonition_block(block, 'tip')
      expect(result.annotation_type).to eq('TIP')
    end
  end
end
