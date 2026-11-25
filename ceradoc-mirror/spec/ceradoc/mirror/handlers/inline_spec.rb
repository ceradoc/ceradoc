# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::Mirror::Handlers::Inline do
  let(:context) { Ceradoc::Mirror::CoreModelToMirror.new }

  describe '.process' do
    it 'processes simple marks' do
      bold = Ceradoc::CoreModel::BoldElement.new(content: 'bold text')
      element = Ceradoc::CoreModel::ParagraphBlock.new(
        children: [bold]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('bold text')
      expect(nodes.first.marks.first.type).to eq('strong')
    end

    it 'processes text content' do
      text = Ceradoc::CoreModel::TextContent.new(text: 'plain text')
      element = Ceradoc::CoreModel::ParagraphBlock.new(
        children: [text]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('plain text')
    end

    it 'processes semantic marks like links' do
      link = Ceradoc::CoreModel::LinkElement.new(
        target: 'https://example.com',
        content: 'Example'
      )
      element = Ceradoc::CoreModel::ParagraphBlock.new(
        children: [link]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('Example')
      expect(nodes.first.marks.first.type).to eq('link')
      expect(nodes.first.marks.first.attrs.href).to eq('https://example.com')
    end
  end

  describe '.text_content' do
    it 'returns nil for empty text' do
      text = Ceradoc::CoreModel::TextContent.new(text: '')
      node = described_class.text_content(text, context: context)
      expect(node).to be_nil
    end

    it 'returns text node' do
      text = Ceradoc::CoreModel::TextContent.new(text: 'hello')
      node = described_class.text_content(text, context: context)
      expect(node.type).to eq('text')
      expect(node.text).to eq('hello')
    end
  end

  describe '.call' do
    it 'handles inline element directly' do
      italic = Ceradoc::CoreModel::ItalicElement.new(content: 'italic text')
      node = described_class.call(italic, context: context)

      expect(node.type).to eq('text')
      expect(node.text).to eq('italic text')
      expect(node.marks.first.type).to eq('emphasis')
    end

    it 'dispatches RawInlineElement to a typed raw_inline node' do
      raw = Ceradoc::CoreModel::RawInlineElement.new(
        content: '<abbr title="x">WYSIWYM</abbr>'
      )
      node = described_class.call(raw, context: context)

      expect(node).to be_a(Ceradoc::Mirror::Node::RawInline)
      expect(node.type).to eq('raw_inline')
      expect(node.text).to eq('<abbr title="x">WYSIWYM</abbr>')
    end

    it 'returns nil for empty raw content' do
      raw = Ceradoc::CoreModel::RawInlineElement.new(content: '')
      node = described_class.call(raw, context: context)
      expect(node).to be_nil
    end
  end

  describe 'round-trip raw_inline' do
    it 'mirror_json → CoreModel → mirror_json preserves the typed node' do
      original = Ceradoc::CoreModel::ParagraphBlock.new(
        children: [Ceradoc::CoreModel::RawInlineElement.new(content: '<b>x</b>')]
      )
      json1 = Ceradoc.serialize(original, to: :mirror_json)

      node = Ceradoc::Mirror.from_hash(JSON.parse(json1))
      document = Ceradoc::Mirror::MirrorToCoreModel.new.call(node)

      raw = Array(document.children).find do |child|
        child.is_a?(Ceradoc::CoreModel::RawInlineElement)
      end
      expect(raw).not_to be_nil
      expect(raw.content).to eq('<b>x</b>')

      json2 = Ceradoc.serialize(document, to: :mirror_json)
      expect(json2).to eq(json1)
    end
  end

  describe 'hard line break (foo +\nbar)' do
    # Author-requested explicit break must map to a distinct ProseMirror
    # node type so downstream renderers can emit `<br>` rather than a
    # soft line wrap. Collapsing to SoftBreak silently lost the break.
    it 'dispatches HardLineBreakElement to a hard_break node' do
      hard_break = Ceradoc::CoreModel::HardLineBreakElement.new(content: '')
      node = described_class.call(hard_break, context: context)

      expect(node).to be_a(Ceradoc::Mirror::Node::HardBreak)
      expect(node.type).to eq('hard_break')
    end

    it 'dispatches LineBreakElement to a soft_break node' do
      soft_break = Ceradoc::CoreModel::LineBreakElement.new(content: '')
      node = described_class.call(soft_break, context: context)

      expect(node).to be_a(Ceradoc::Mirror::Node::SoftBreak)
      expect(node.type).to eq('soft_break')
    end

    it 'round-trips hard_break through mirror_json → CoreModel → mirror_json' do
      original = Ceradoc::CoreModel::ParagraphBlock.new(
        children: [
          Ceradoc::CoreModel::TextContent.new(text: 'foo'),
          Ceradoc::CoreModel::HardLineBreakElement.new(content: ''),
          Ceradoc::CoreModel::TextContent.new(text: 'bar')
        ]
      )
      json1 = Ceradoc.serialize(original, to: :mirror_json)

      parsed_node = Ceradoc::Mirror.from_hash(JSON.parse(json1))
      document = Ceradoc::Mirror::MirrorToCoreModel.new.call(parsed_node)

      hard_break = Array(document.children).find do |child|
        child.is_a?(Ceradoc::CoreModel::HardLineBreakElement)
      end
      expect(hard_break).not_to be_nil

      json2 = Ceradoc.serialize(document, to: :mirror_json)
      expect(json2).to eq(json1)
    end
  end
end
