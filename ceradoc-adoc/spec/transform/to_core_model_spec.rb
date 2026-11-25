# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::AsciiDoc::Transform::ToCoreModel do
  let(:transformer) { described_class.new }

  describe '#transform' do
    context 'when transforming a document' do
      it 'transforms an AsciiDoc document to CoreModel' do
        header = Ceradoc::AsciiDoc::Model::Header.new(
          title: Ceradoc::AsciiDoc::Model::Title.new(content: 'Test Document')
        )
        doc = Ceradoc::AsciiDoc::Model::Document.new(
          header: header,
          sections: []
        )

        result = transformer.transform(doc)

        expect(result).to be_a(Ceradoc::CoreModel::DocumentElement)
        expect(result.document?).to be true
        expect(result.title).to eq('Test Document')
      end
    end

    context 'when transforming a section' do
      it 'transforms an AsciiDoc section to CoreModel' do
        section = Ceradoc::AsciiDoc::Model::Section.new(
          id: 'intro',
          level: 1,
          title: Ceradoc::AsciiDoc::Model::Title.new(content: 'Introduction'),
          contents: []
        )

        result = transformer.transform(section)

        expect(result).to be_a(Ceradoc::CoreModel::SectionElement)
        expect(result.section?).to be true
        expect(result.level).to eq(1)
        expect(result.title).to eq('Introduction')
        expect(result.id).to eq('intro')
      end
    end

    context 'when transforming a block' do
      it 'transforms an AsciiDoc block to CoreModel' do
        block = Ceradoc::AsciiDoc::Model::Block::Core.new(
          id: 'example-1',
          delimiter: '====',
          lines: ['Line 1', 'Line 2']
        )

        result = transformer.transform(block)

        expect(result).to be_a(Ceradoc::CoreModel::Block)
        expect(result.block_semantic_type).to eq('example')
        expect(result.delimiter_type).to eq('====')
        expect(result.content).to eq("Line 1\nLine 2")
      end
    end

    context 'when transforming an array' do
      it 'transforms each element in the collection' do
        sections = [
          Ceradoc::AsciiDoc::Model::Section.new(
            level: 1,
            title: Ceradoc::AsciiDoc::Model::Title.new(content: 'Section 1')
          ),
          Ceradoc::AsciiDoc::Model::Section.new(
            level: 1,
            title: Ceradoc::AsciiDoc::Model::Title.new(content: 'Section 2')
          )
        ]

        result = transformer.transform(sections)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Ceradoc::CoreModel::SectionElement)
      end
    end
  end
end
