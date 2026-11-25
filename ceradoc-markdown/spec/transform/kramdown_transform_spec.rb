# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/markdown'
require 'ceradoc/markdown/transform/to_core_model'
require 'ceradoc/markdown/transform/from_core_model'

RSpec.describe Ceradoc::Markdown::Transform::ToCoreModel do
  describe 'DefinitionList transformation' do
    it 'transforms definition list to CoreModel DefinitionList' do
      term = Ceradoc::Markdown::DefinitionTerm.new(
        text: 'API',
        definitions: [Ceradoc::Markdown::DefinitionItem.new(content: 'Application Programming Interface')]
      )
      dl = Ceradoc::Markdown::DefinitionList.new(items: [term])

      result = described_class.transform(dl)

      expect(result).to be_a(Ceradoc::CoreModel::DefinitionList)
      expect(result.items.first.term).to eq('API')
      expect(result.items.first.definitions).to eq(['Application Programming Interface'])
    end

    it 'transforms definition list with multiple definitions' do
      term = Ceradoc::Markdown::DefinitionTerm.new(
        text: 'API',
        definitions: [
          Ceradoc::Markdown::DefinitionItem.new(content: 'First definition'),
          Ceradoc::Markdown::DefinitionItem.new(content: 'Second definition')
        ]
      )
      dl = Ceradoc::Markdown::DefinitionList.new(items: [term])

      result = described_class.transform(dl)

      expect(result.items.first.definitions.length).to eq(2)
    end
  end

  describe 'Footnote transformation' do
    it 'transforms footnote to CoreModel Footnote' do
      fn = Ceradoc::Markdown::Footnote.new(id: 'fn1', content: 'This is a footnote')

      result = described_class.transform(fn)

      expect(result).to be_a(Ceradoc::CoreModel::Footnote)
      expect(result.id).to eq('fn1')
      expect(result.content).to eq('This is a footnote')
    end

    it 'transforms footnote with backlink disabled' do
      fn = Ceradoc::Markdown::Footnote.new(id: '1', content: 'No backlink', backlink: false)

      result = described_class.transform(fn)

      expect(result.backlink).to be false
    end

    it 'defaults backlink to true' do
      fn = Ceradoc::Markdown::Footnote.new(id: '1', content: 'Default backlink')

      result = described_class.transform(fn)

      expect(result.backlink).to be true
    end
  end

  describe 'FootnoteReference transformation' do
    it 'transforms footnote reference to CoreModel FootnoteReference' do
      ref = Ceradoc::Markdown::FootnoteReference.new(id: 'fn1')

      result = described_class.transform(ref)

      expect(result).to be_a(Ceradoc::CoreModel::FootnoteReference)
      expect(result.id).to eq('fn1')
    end
  end

  describe 'Abbreviation transformation' do
    it 'transforms abbreviation to CoreModel Abbreviation' do
      abbr = Ceradoc::Markdown::Abbreviation.new(term: 'API', definition: 'Application Programming Interface')

      result = described_class.transform(abbr)

      expect(result).to be_a(Ceradoc::CoreModel::Abbreviation)
      expect(result.term).to eq('API')
      expect(result.definition).to eq('Application Programming Interface')
    end
  end
end

RSpec.describe Ceradoc::Markdown::Transform::FromCoreModel do
  describe 'DefinitionList transformation' do
    it 'transforms CoreModel DefinitionList to Markdown DefinitionList' do
      item = Ceradoc::CoreModel::DefinitionItem.new(
        term: 'API',
        definitions: ['Application Programming Interface']
      )
      dl = Ceradoc::CoreModel::DefinitionList.new(items: [item])

      result = described_class.transform(dl)

      expect(result).to be_a(Ceradoc::Markdown::DefinitionList)
      expect(result.items.first.text).to eq('API')
      expect(result.items.first.definitions.first.content).to eq('Application Programming Interface')
    end
  end

  describe 'Footnote transformation' do
    it 'transforms CoreModel Footnote to Markdown Footnote' do
      fn = Ceradoc::CoreModel::Footnote.new(id: 'fn1', content: 'This is a footnote')

      result = described_class.transform(fn)

      expect(result).to be_a(Ceradoc::Markdown::Footnote)
      expect(result.id).to eq('fn1')
      expect(result.content).to eq('This is a footnote')
    end

    it 'transforms footnote with backlink disabled' do
      fn = Ceradoc::CoreModel::Footnote.new(id: '1', content: 'No backlink', backlink: false)

      result = described_class.transform(fn)

      expect(result.backlink).to be false
    end
  end

  describe 'FootnoteReference transformation' do
    it 'transforms CoreModel FootnoteReference to Markdown FootnoteReference' do
      ref = Ceradoc::CoreModel::FootnoteReference.new(id: 'fn1')

      result = described_class.transform(ref)

      expect(result).to be_a(Ceradoc::Markdown::FootnoteReference)
      expect(result.id).to eq('fn1')
    end
  end

  describe 'Abbreviation transformation' do
    it 'transforms CoreModel Abbreviation to Markdown Abbreviation' do
      abbr = Ceradoc::CoreModel::Abbreviation.new(term: 'API', definition: 'Application Programming Interface')

      result = described_class.transform(abbr)

      expect(result).to be_a(Ceradoc::Markdown::Abbreviation)
      expect(result.term).to eq('API')
      expect(result.definition).to eq('Application Programming Interface')
    end
  end

  describe 'InlineElement footnote format_type' do
    it 'transforms inline element with format_type footnote to FootnoteReference' do
      inline = Ceradoc::CoreModel::InlineElement.new(
        format_type: 'footnote',
        target: 'fn1',
        content: 'reference'
      )

      result = described_class.transform(inline)

      expect(result).to be_a(Ceradoc::Markdown::FootnoteReference)
      expect(result.id).to eq('fn1')
    end
  end

  describe 'Round-trip transformation' do
    it 'preserves definition list through round-trip' do
      term = Ceradoc::Markdown::DefinitionTerm.new(
        text: 'API',
        definitions: [Ceradoc::Markdown::DefinitionItem.new(content: 'Application Programming Interface')]
      )
      original = Ceradoc::Markdown::DefinitionList.new(items: [term])

      core = Ceradoc::Markdown::Transform::ToCoreModel.transform(original)
      restored = described_class.transform(core)

      expect(restored.items.first.text).to eq(original.items.first.text)
    end

    it 'preserves footnote through round-trip' do
      original = Ceradoc::Markdown::Footnote.new(id: 'fn1', content: 'A footnote', backlink: false)

      core = Ceradoc::Markdown::Transform::ToCoreModel.transform(original)
      restored = described_class.transform(core)

      expect(restored.id).to eq(original.id)
      expect(restored.content).to eq(original.content)
      expect(restored.backlink).to eq(original.backlink)
    end

    it 'preserves abbreviation through round-trip' do
      original = Ceradoc::Markdown::Abbreviation.new(term: 'API', definition: 'Application Programming Interface')

      core = Ceradoc::Markdown::Transform::ToCoreModel.transform(original)
      restored = described_class.transform(core)

      expect(restored.term).to eq(original.term)
      expect(restored.definition).to eq(original.definition)
    end
  end
end
