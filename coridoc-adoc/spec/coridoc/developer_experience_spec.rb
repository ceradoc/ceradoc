# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer Experience API' do
  # Load coridoc core and asciidoc

  describe 'Coridoc.parse' do
    it 'parses AsciiDoc text to CoreModel' do
      text = "= Document Title\n\n== Section\n\nContent here."

      result = Coridoc.parse(text, format: :asciidoc)

      expect(result).to be_a(Coridoc::CoreModel::DocumentElement)
      expect(result.document?).to be true
    end

    it 'raises error for unregistered format' do
      expect do
        Coridoc.parse('text', format: :unknown)
      end.to raise_error(Coridoc::UnsupportedFormatError, /not registered/)
    end

    it 'lists available formats in error message' do
      expect do
        Coridoc.parse('text', format: :unknown)
      end.to raise_error(/Available formats:.*asciidoc/)
    end
  end

  describe 'Coridoc.convert' do
    it 'converts AsciiDoc to AsciiDoc (round-trip)' do
      input = "= Title\n\n== Section\n\nParagraph."

      result = Coridoc.convert(input, from: :asciidoc, to: :asciidoc)

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

      result = Coridoc.convert(input, from: :asciidoc, to: :asciidoc)

      expect(result).to include('Introduction')
      expect(result).to include('Item 1')
      expect(result).to include('Details')
    end

    it 'raises error for unknown source format' do
      expect do
        Coridoc.convert('text', from: :unknown, to: :asciidoc)
      end.to raise_error(Coridoc::UnsupportedFormatError)
    end

    it 'raises error for unknown target format' do
      expect do
        Coridoc.convert('text', from: :asciidoc, to: :unknown)
      end.to raise_error(Coridoc::UnsupportedFormatError)
    end
  end

  describe 'Coridoc.serialize' do
    it 'serializes CoreModel to AsciiDoc' do
      core = Coridoc::CoreModel::DocumentElement.new(
        title: 'My Document',
        children: []
      )

      result = Coridoc.serialize(core, to: :asciidoc)

      expect(result).to include('My Document')
    end
  end

  describe 'Coridoc.to_core' do
    it 'returns CoreModel as-is' do
      core = Coridoc::CoreModel::Block.new(content: 'test')

      result = Coridoc.to_core(core)

      expect(result).to eq(core)
    end

    it 'transforms AsciiDoc model to CoreModel' do
      adoc = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Hello')]
      )

      result = Coridoc.to_core(adoc)

      expect(result).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.resolve_semantic_type).to eq(:paragraph)
    end
  end

  describe 'format registration' do
    it 'lists registered formats' do
      expect(Coridoc.registered_formats).to include(:asciidoc)
    end

    it 'returns format module' do
      expect(Coridoc.get_format(:asciidoc)).to eq(Coridoc::AsciiDoc)
    end
  end
end
