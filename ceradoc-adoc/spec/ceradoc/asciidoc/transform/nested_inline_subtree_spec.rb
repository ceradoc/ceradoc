# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested inline subtree serialization (#372)' do
  # The HTML Markup converter parks an inline element's subtree under
  # `nested_elements` as ordered InlineElement children (TextElement
  # for text runs) while `content` stays empty. The writer must walk
  # that carrier or the styled content is silently dropped.
  def nested_text(text)
    Ceradoc::CoreModel::TextElement.new(content: text)
  end

  describe 'nested_elements carrier (HTML Markup converter)' do
    it 'renders bold text parked under nested_elements' do
      bold = Ceradoc::CoreModel::BoldElement.new(
        content: '',
        nested_elements: [nested_text('world')]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(bold).to_adoc)
        .to eq('*world*')
    end

    it 'renders italic text parked under nested_elements' do
      italic = Ceradoc::CoreModel::ItalicElement.new(
        content: '',
        nested_elements: [nested_text('soft')]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(italic).to_adoc)
        .to eq('_soft_')
    end

    it 'renders nested italic inside bold with italic innermost' do
      bold = Ceradoc::CoreModel::BoldElement.new(
        content: '',
        nested_elements: [
          Ceradoc::CoreModel::ItalicElement.new(
            content: '',
            nested_elements: [nested_text('both')]
          )
        ]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(bold).to_adoc)
        .to eq('*_both_*')
    end

    it 'renders nested bold inside italic with italic innermost' do
      italic = Ceradoc::CoreModel::ItalicElement.new(
        content: '',
        nested_elements: [
          Ceradoc::CoreModel::BoldElement.new(
            content: '',
            nested_elements: [nested_text('both')]
          )
        ]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(italic).to_adoc)
        .to eq('*_both_*')
    end

    it 'renders text siblings around a nested element in order' do
      bold = Ceradoc::CoreModel::BoldElement.new(
        content: '',
        nested_elements: [
          nested_text('x'),
          Ceradoc::CoreModel::ItalicElement.new(
            content: '',
            nested_elements: [nested_text('y')]
          ),
          nested_text('b')
        ]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(bold).to_adoc)
        .to eq('*x__y__b*')
    end

    it 'walks the subtree for the generic format types' do
      monospace = Ceradoc::CoreModel::InlineElement.new(
        format_type: 'monospace',
        content: '',
        nested_elements: [nested_text('code')]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(monospace).to_adoc)
        .to eq('`code`')
    end

    it 'keeps the subtree as markup in the text fallback branch' do
      anchor = Ceradoc::CoreModel::InlineElement.new(
        format_type: 'anchor',
        target: 'intro',
        content: '',
        nested_elements: [nested_text('anchor text')]
      )

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(anchor).to_adoc)
        .to eq('anchor text')
    end
  end

  describe 'children carrier (AsciiDoc/docx parse path) stays intact' do
    it 'renders bold from children' do
      bold = Ceradoc::CoreModel::BoldElement.new(children: ['kept'])

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(bold).to_adoc)
        .to eq('*kept*')
    end

    it 'renders bold from the flat content string' do
      bold = Ceradoc::CoreModel::BoldElement.new(content: 'flat')

      expect(Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(bold).to_adoc)
        .to eq('*flat*')
    end
  end
end
