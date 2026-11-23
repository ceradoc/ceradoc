# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::ElementTransformers::BlockTransformer do
  describe '.transform_paragraph' do
    it 'transforms a basic paragraph with plain text' do
      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        id: 'para-1',
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Hello world')]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.id).to eq('para-1')
      expect(result.content).to eq('Hello world')
      expect(result.lines).to eq(['Hello world'])
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Coridoc::CoreModel::TextContent)
    end

    it 'preserves source line structure for multi-line paragraphs' do
      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'This is line one', line_break: "\n"),
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'of a paragraph', line_break: "\n"),
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'that spans three.')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coridoc::CoreModel::ParagraphBlock)
      # `content` is the rendered view — soft-wrapped lines joined with
      # spaces so they read as flowing prose.
      expect(result.content).to eq('This is line one of a paragraph that spans three.')
      # `lines` is the source-line view — each entry corresponds to one
      # line in the AsciiDoc source.
      expect(result.lines).to eq(['This is line one', 'of a paragraph', 'that spans three.'])
    end

    it 'filters out LineBreak and PageBreak items when extracting source lines' do
      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'Before'),
          Coridoc::AsciiDoc::Model::LineBreak.new,
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'After')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result.lines).to eq(%w[Before After])
    end

    it 'transforms a paragraph with inline elements' do
      inline_text = Coridoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          inline_text,
          Coridoc::AsciiDoc::Model::TextElement.new(content: ' world')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.content).to match(/Hello\s+bold\s*world/)
      # Inline elements between two TextElements do NOT synthesize a
      # soft-break space — the visitor only inserts " " between two
      # adjacent TextElements (i.e. real source line breaks). An
      # inline element sitting between two text runs means the source
      # had them on the same line.
      expect(result.children.size).to eq(3)
      expect(result.children.find { |c| c.is_a?(Coridoc::CoreModel::BoldElement) }).not_to be_nil
      expect(result.children.find { |c| c.is_a?(Coridoc::CoreModel::BoldElement) }.content).to eq('bold')
    end

    it 'handles empty content' do
      para = Coridoc::AsciiDoc::Model::Paragraph.new(content: [])

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.content).to eq('')
      expect(result.children).to be_empty
    end
  end

  describe '.transform_source_block' do
    it 'transforms a source block with language' do
      attr_list = Coridoc::AsciiDoc::Model::AttributeList.new(
        positional: [
          Coridoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'source'),
          Coridoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'ruby')
        ]
      )
      title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Example')])
      block = Coridoc::AsciiDoc::Model::Block::SourceCode.new(
        id: 'src-1',
        title: title,
        attributes: attr_list,
        lines: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'def test'),
          Coridoc::AsciiDoc::Model::LineBreak.new,
          Coridoc::AsciiDoc::Model::TextElement.new(content: '  true'),
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'end')
        ]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Coridoc::CoreModel::SourceBlock)
      expect(result.id).to eq('src-1')
      expect(result.title).to eq('Example')
      expect(result.language).to eq('ruby')
      expect(result.content).to eq("def test\n  true\nend")
      expect(result.lines).to eq(['def test', '  true', 'end'])
    end

    it 'handles source block without language' do
      block = Coridoc::AsciiDoc::Model::Block::SourceCode.new(
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'plain code')]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Coridoc::CoreModel::SourceBlock)
      expect(result.language).to be_nil
      expect(result.content).to eq('plain code')
    end
  end

  describe '.transform_block' do
    it 'transforms a block with a string delimiter' do
      title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Note')])
      block = Coridoc::AsciiDoc::Model::Block::Core.new(
        id: 'blk-1',
        title: title,
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Note content')]
      )

      result = described_class.transform_block(block, '====')

      expect(result).to be_a(Coridoc::CoreModel::Block)
      expect(result.id).to eq('blk-1')
      expect(result.title).to eq('Note')
      expect(result.content).to eq('Note content')
      expect(result.lines).to eq(['Note content'])
      expect(result.block_semantic_type).to eq('example')
      expect(result.delimiter_type).to eq('====')
    end

    it 'transforms a block with a symbol semantic type' do
      block = Coridoc::AsciiDoc::Model::Block::Core.new(
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Sidebar content')]
      )

      result = described_class.transform_block(block, :sidebar)

      expect(result).to be_a(Coridoc::CoreModel::Block)
      expect(result.content).to eq('Sidebar content')
      expect(result.block_semantic_type.to_s).to eq('sidebar')
      expect(result.delimiter_type).to be_nil
    end
  end

  describe '.transform_typed_block' do
    it 'transforms into a specified class with simple lines' do
      title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Quote')])
      block = Coridoc::AsciiDoc::Model::Block::Quote.new(
        id: 'quote-1',
        title: title,
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'To be or not to be')]
      )

      result = described_class.transform_typed_block(
        block, Coridoc::CoreModel::QuoteBlock, { attribution: 'Shakespeare' }
      )

      expect(result).to be_a(Coridoc::CoreModel::QuoteBlock)
      expect(result.id).to eq('quote-1')
      expect(result.title).to eq('Quote')
      expect(result.content).to eq('To be or not to be')
      expect(result.attribution).to eq('Shakespeare')
      expect(result.children).to all(be_a(Coridoc::CoreModel::ParagraphBlock))
    end

    it 'groups consecutive soft-wrapped lines into a single paragraph' do
      block = Coridoc::AsciiDoc::Model::Block::Example.new(
        lines: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 1.', line_break: "\n"),
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 2.', line_break: "\n"),
          Coridoc::AsciiDoc::Model::LineBreak.new,
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'Second paragraph here.')
        ]
      )

      result = described_class.transform_typed_block(
        block, Coridoc::CoreModel::ExampleBlock
      )

      paragraphs = result.children
      expect(paragraphs.size).to eq(2)
      expect(paragraphs.all?(Coridoc::CoreModel::ParagraphBlock)).to be(true)
      expect(paragraphs[0].content).to eq('First paragraph line 1. First paragraph line 2.')
      expect(paragraphs[1].content).to eq('Second paragraph here.')
    end

    it 'transforms into a specified class with nested blocks' do
      nested = Coridoc::AsciiDoc::Model::Block::Core.new(
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Inner')]
      )
      block = Coridoc::AsciiDoc::Model::Block::Example.new(
        lines: [nested]
      )

      result = described_class.transform_typed_block(
        block, Coridoc::CoreModel::ExampleBlock
      )

      expect(result).to be_a(Coridoc::CoreModel::ExampleBlock)
      expect(result.content).to be_nil
      expect(result.children).to be_an(Array)
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Coridoc::CoreModel::Block)
    end

    it 'preserves inline formatting when inline prose sits alongside a nested list' do
      link = Coridoc::AsciiDoc::Model::Inline::Link.new(
        path: 'foo.html', name: 'Simple Adoption'
      )
      text_line = Coridoc::AsciiDoc::Model::TextElement.new(
        content: [
          'The easiest way is via ',
          link,
          '.'
        ]
      )
      list = Coridoc::AsciiDoc::Model::List::Unordered.new(
        items: [Coridoc::AsciiDoc::Model::List::Item.new(
          content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'item')],
          marker: '*'
        )]
      )
      block = Coridoc::AsciiDoc::Model::Block::Example.new(lines: [text_line, list])

      result = described_class.transform_typed_block(
        block, Coridoc::CoreModel::ExampleBlock
      )

      expect(result.children.size).to eq(2)
      expect(result.children[0]).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.children[1]).to be_a(Coridoc::CoreModel::ListBlock)

      paragraph = result.children[0]
      link_element = paragraph.children.find { |c| c.is_a?(Coridoc::CoreModel::LinkElement) }
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
      nested = Coridoc::AsciiDoc::Model::Block::Core.new(
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Inner')]
      )

      children, content = build([nested])
      expect(content).to be_nil
      expect(children.size).to eq(1)
      expect(children.first).to be_a(Coridoc::CoreModel::Block)
    end

    it 'joins multiple paragraph texts with blank-line separator in content' do
      lines = [
        Coridoc::AsciiDoc::Model::TextElement.new(content: 'First.'),
        Coridoc::AsciiDoc::Model::LineBreak.new,
        Coridoc::AsciiDoc::Model::TextElement.new(content: 'Second.')
      ]

      children, content = build(lines)
      expect(children.size).to eq(2)
      expect(content).to eq("First.\n\nSecond.")
    end

    it 'flushes the pending paragraph when a block-level child appears mid-stream' do
      list = Coridoc::AsciiDoc::Model::List::Unordered.new(
        items: [Coridoc::AsciiDoc::Model::List::Item.new(
          content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'item')],
          marker: '*'
        )]
      )
      lines = [
        Coridoc::AsciiDoc::Model::TextElement.new(content: 'Before list.'),
        list
      ]

      children, content = build(lines)
      expect(children.map(&:class)).to eq([
                                            Coridoc::CoreModel::ParagraphBlock,
                                            Coridoc::CoreModel::ListBlock
                                          ])
      expect(content).to eq('Before list.')
    end
  end

  describe '.transform_admonition_block' do
    it 'builds an AnnotationBlock with annotation_type and ParagraphBlock children' do
      link = Coridoc::AsciiDoc::Model::Inline::Link.new(
        path: 'foo.html', name: 'bar'
      )
      text_line = Coridoc::AsciiDoc::Model::TextElement.new(
        content: ['See ', link, '.']
      )
      block = Coridoc::AsciiDoc::Model::Block::Example.new(lines: [text_line])

      result = described_class.transform_admonition_block(block, 'note')

      expect(result).to be_a(Coridoc::CoreModel::AnnotationBlock)
      expect(result.annotation_type).to eq('NOTE')
      paragraph = result.children.first
      expect(paragraph).to be_a(Coridoc::CoreModel::ParagraphBlock)
      link_element = paragraph.children.find { |c| c.is_a?(Coridoc::CoreModel::LinkElement) }
      expect(link_element&.target).to eq('foo.html')
    end

    it 'canoninalises the type via AdmonitionStyles' do
      block = Coridoc::AsciiDoc::Model::Block::Example.new(
        lines: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'body')]
      )

      result = described_class.transform_admonition_block(block, 'tip')
      expect(result.annotation_type).to eq('TIP')
    end
  end
end
