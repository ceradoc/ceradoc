# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer Experience API' do
  # Load ceradoc core and asciidoc

  describe 'Ceradoc.parse' do
    it 'parses AsciiDoc text to CoreModel' do
      text = "= Document Title\n\n== Section\n\nContent here."

      result = Ceradoc.parse(text, format: :asciidoc)

      expect(result).to be_a(Ceradoc::CoreModel::DocumentElement)
      expect(result.document?).to be true
    end

    it 'raises error for unregistered format' do
      expect do
        Ceradoc.parse('text', format: :unknown)
      end.to raise_error(Ceradoc::UnsupportedFormatError, /not registered/)
    end

    it 'lists available formats in error message' do
      expect do
        Ceradoc.parse('text', format: :unknown)
      end.to raise_error(/Available formats:.*asciidoc/)
    end
  end

  describe 'Ceradoc.convert' do
    it 'converts AsciiDoc to AsciiDoc (round-trip)' do
      input = "= Title\n\n== Section\n\nParagraph."

      result = Ceradoc.convert(input, from: :asciidoc, to: :asciidoc)

      expect(result).to include('Title')
      expect(result).to include('Section')
      expect(result).to include('Paragraph')
    end

    it 'preserves document structure in conversion' do
      input = <<~ADOC
        = Complex Document

        == Introduction

        Some intro text.

        * Item 1
        * Item 2

        == Details

        More details here.
      ADOC

      result = Ceradoc.convert(input, from: :asciidoc, to: :asciidoc)

      expect(result).to include('Introduction')
      expect(result).to include('Item 1')
      expect(result).to include('Details')
    end

    it 'raises error for unknown source format' do
      expect do
        Ceradoc.convert('text', from: :unknown, to: :asciidoc)
      end.to raise_error(Ceradoc::UnsupportedFormatError)
    end

    it 'raises error for unknown target format' do
      expect do
        Ceradoc.convert('text', from: :asciidoc, to: :unknown)
      end.to raise_error(Ceradoc::UnsupportedFormatError)
    end
  end

  describe 'Ceradoc.serialize' do
    it 'serializes CoreModel to AsciiDoc' do
      core = Ceradoc::CoreModel::DocumentElement.new(
        title: 'My Document',
        children: []
      )

      result = Ceradoc.serialize(core, to: :asciidoc)

      expect(result).to include('My Document')
    end
  end

  describe 'Ceradoc.to_core' do
    it 'returns CoreModel as-is' do
      core = Ceradoc::CoreModel::Block.new(content: 'test')

      result = Ceradoc.to_core(core)

      expect(result).to eq(core)
    end

    it 'transforms AsciiDoc model to CoreModel' do
      adoc = Ceradoc::AsciiDoc::Model::Paragraph.new(
        content: [Ceradoc::AsciiDoc::Model::TextElement.new(content: 'Hello')]
      )

      result = Ceradoc.to_core(adoc)

      expect(result).to be_a(Ceradoc::CoreModel::ParagraphBlock)
      expect(result.resolve_semantic_type).to eq(:paragraph)
    end
  end

  describe 'format registration' do
    it 'lists registered formats' do
      expect(Ceradoc.registered_formats).to include(:asciidoc)
    end

    it 'returns format module' do
      expect(Ceradoc.get_format(:asciidoc)).to eq(Ceradoc::AsciiDoc)
    end
  end
end
