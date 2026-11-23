# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::ElementTransformers::InlineTransformer do
  describe '.transform_inline' do
    it 'transforms basic inline element' do
      inline = Coridoc::AsciiDoc::Model::TextElement.new(
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'highlight')]
      )

      result = described_class.transform_inline(inline, 'mark')

      expect(result).to be_a(Coridoc::CoreModel::InlineElement)

      expect(result.content).to eq('highlight')
    end

    it 'handles empty content' do
      inline = Coridoc::AsciiDoc::Model::TextElement.new(content: [])

      result = described_class.transform_inline(inline, 'bold')

      expect(result).to be_a(Coridoc::CoreModel::BoldElement)
      expect(result.content).to eq('')
    end
  end

  describe '.transform_inline_text' do
    it 'transforms inline text to specified format type' do
      inline_text = Coridoc::AsciiDoc::Model::TextElement.new(content: 'emphasized')

      result = described_class.transform_inline_text(inline_text, 'italic')

      expect(result).to be_a(Coridoc::CoreModel::ItalicElement)
      expect(result.content).to eq('emphasized')
    end
  end

  describe '.transform_inline_footnote' do
    it 'transforms footnote with text' do
      footnote = Coridoc::AsciiDoc::Model::Inline::Footnote.new(
        id: 'fn-1',
        text: 'This is a footnote.'
      )

      result = described_class.transform_inline_footnote(footnote)

      expect(result).to be_a(Coridoc::CoreModel::FootnoteElement)
      expect(result.target).to eq('fn-1')
      # Content parsed by ToCoreModel.parse_and_transform_inline
      expect(result.content).to eq('This is a footnote.')
    end
  end

  describe '.transform_link' do
    it 'transforms a link with explicit text' do
      link = Coridoc::AsciiDoc::Model::Inline::Link.new(
        path: 'https://example.com',
        name: 'Example Domain'
      )

      result = described_class.transform_link(link)

      expect(result).to be_a(Coridoc::CoreModel::LinkElement)
      expect(result.target).to eq('https://example.com')
      expect(result.content).to eq('Example Domain')
    end

    it 'transforms a link without text (falls back to path)' do
      link = Coridoc::AsciiDoc::Model::Inline::Link.new(
        path: 'https://example.com',
        name: nil
      )

      result = described_class.transform_link(link)

      expect(result).to be_a(Coridoc::CoreModel::LinkElement)
      expect(result.target).to eq('https://example.com')
      expect(result.content).to eq('https://example.com')
    end
  end

  describe '.transform_cross_reference' do
    it 'transforms an xref with text' do
      xref = Coridoc::AsciiDoc::Model::Inline::CrossReference.new(
        href: 'section-1',
        args: ['Section One']
      )

      result = described_class.transform_cross_reference(xref)

      expect(result).to be_a(Coridoc::CoreModel::CrossReferenceElement)
      expect(result.target).to eq('section-1')
      expect(result.content).to eq('Section One')
    end

    it 'transforms an xref without text (falls back to href)' do
      xref = Coridoc::AsciiDoc::Model::Inline::CrossReference.new(
        href: 'section-2',
        args: nil
      )

      result = described_class.transform_cross_reference(xref)

      expect(result).to be_a(Coridoc::CoreModel::CrossReferenceElement)
      expect(result.target).to eq('section-2')
      expect(result.content).to eq('section-2')
    end
  end

  describe '.transform_stem' do
    it 'transforms a stem element' do
      stem = Coridoc::AsciiDoc::Model::Inline::Stem.new(
        content: 'E = mc^2',
        type: 'latexmath'
      )

      result = described_class.transform_stem(stem)

      expect(result).to be_a(Coridoc::CoreModel::StemElement)
      expect(result.content).to eq('E = mc^2')
      expect(result.stem_type).to eq('latexmath')
    end

    it 'defaults stem_type to stem if not provided' do
      stem = Coridoc::AsciiDoc::Model::Inline::Stem.new(
        content: 'x^2',
        type: nil
      )

      result = described_class.transform_stem(stem)

      expect(result).to be_a(Coridoc::CoreModel::StemElement)
      expect(result.content).to eq('x^2')
      expect(result.stem_type).to eq('stem')
    end
  end
end
