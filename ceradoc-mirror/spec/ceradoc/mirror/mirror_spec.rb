# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::Mirror do
  describe '.default_registry' do
    it 'returns a HandlerRegistry with core handlers' do
      registry = described_class.default_registry
      expect(registry).to be_a(Ceradoc::Mirror::HandlerRegistry)

      # Verify key registrations
      expect(registry.registered?(Ceradoc::CoreModel::DocumentElement)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::SectionElement)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::ParagraphBlock)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::SourceBlock)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::ListBlock)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::Table)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::Image)).to be true
      expect(registry.registered?(Ceradoc::CoreModel::AnnotationBlock)).to be true
    end
  end

  describe '.transform' do
    it 'transforms a CoreModel document to mirror in one call' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        title: 'Quick Test',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'Hello')
        ]
      )

      result = described_class.transform(doc)
      expect(result).to be_a(Ceradoc::Mirror::Node::Document)
      expect(result.attrs.title).to eq('Quick Test')
    end
  end

  describe '.to_json' do
    it 'transforms and serializes to JSON' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        title: 'JSON Test',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'World')
        ]
      )

      json = described_class.to_json(doc)
      parsed = JSON.parse(json)
      expect(parsed['type']).to eq('doc')
      expect(parsed['attrs']['title']).to eq('JSON Test')
    end

    it 'produces pretty JSON when requested' do
      doc = Ceradoc::CoreModel::DocumentElement.new(title: 'Pretty')
      json = described_class.to_json(doc, pretty: true)
      expect(json).to include("\n")
      expect(json).to include('  ')
    end
  end

  describe 'VERSION' do
    it 'has a version constant' do
      expect(Ceradoc::Mirror::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
