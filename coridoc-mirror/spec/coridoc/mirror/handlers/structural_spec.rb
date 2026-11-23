# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::Mirror::Handlers::Structural do
  let(:context) { Coridoc::Mirror::CoreModelToMirror.new }

  describe '.document' do
    it 'creates a document node' do
      element = Coridoc::CoreModel::DocumentElement.new(
        title: 'Test Document',
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: 'Content')]
      )

      node = described_class.document(element, context: context)
      expect(node).to be_a(Coridoc::Mirror::Node::Document)
      expect(node.type).to eq('doc')
      expect(node.attrs.title).to eq('Test Document')
      expect(node.content.length).to eq(1)
    end
  end

  describe '.section' do
    it 'creates a section node' do
      element = Coridoc::CoreModel::SectionElement.new(
        id: 'sec-1',
        title: 'Test Section',
        level: 2,
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: 'Content')]
      )

      node = described_class.section(element, context: context)
      expect(node).to be_a(Coridoc::Mirror::Node::Section)
      expect(node.type).to eq('section')
      expect(node.attrs.id).to eq('sec-1')
      expect(node.attrs.title).to eq('Test Section')
      expect(node.attrs.level).to eq(2)
      expect(node.content.length).to eq(1)
    end
  end

  describe '.preamble' do
    it 'creates a preamble node' do
      element = Coridoc::CoreModel::PreambleElement.new(
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: 'Content')]
      )

      node = described_class.preamble(element, context: context)
      expect(node).to be_a(Coridoc::Mirror::Node::Preamble)
      expect(node.type).to eq('preface')
      expect(node.content.length).to eq(1)
    end
  end

  describe '.header' do
    it 'creates a header node' do
      element = Coridoc::CoreModel::HeaderElement.new(
        title: 'Main Title',
        level: 1,
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: 'Author info')]
      )

      node = described_class.header(element, context: context)
      expect(node).to be_a(Coridoc::Mirror::Node::Header)
      expect(node.type).to eq('floating_title')
      expect(node.attrs.title).to eq('Main Title')
      expect(node.attrs.level).to eq(1)
      expect(node.content.length).to eq(1)
    end
  end
end
