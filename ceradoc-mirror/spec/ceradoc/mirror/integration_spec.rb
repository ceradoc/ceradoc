# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'

RSpec.describe 'End-to-end integration' do
  describe 'YAML output' do
    it 'produces valid YAML output' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        title: 'YAML Test',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'Hello')
        ]
      )

      yaml = Ceradoc::Mirror.to_yaml(doc)
      parsed = YAML.safe_load(yaml)
      expect(parsed['type']).to eq('doc')
      expect(parsed['attrs']['title']).to eq('YAML Test')
    end

    it 'round-trips YAML serialization' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        title: 'YAML Round Trip',
        children: [
          Ceradoc::CoreModel::SectionElement.new(
            title: 'Section',
            level: 1,
            children: [
              Ceradoc::CoreModel::ParagraphBlock.new(content: 'Text')
            ]
          )
        ]
      )

      yaml = Ceradoc::Mirror.to_yaml(doc)
      mirror_node = Ceradoc::Mirror.from_hash(YAML.safe_load(yaml))
      expect(mirror_node).to be_a(Ceradoc::Mirror::Node::Document)
      expect(mirror_node.attrs.title).to eq('YAML Round Trip')
    end
  end

  describe 'Transformer facade' do
    it 'supports forward and reverse transformation' do
      transformer = Ceradoc::Mirror::Transformer.new

      doc = Ceradoc::CoreModel::DocumentElement.new(
        title: 'Test',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'Content')
        ]
      )

      mirror = transformer.from_core_model(doc)
      expect(mirror).to be_a(Ceradoc::Mirror::Node::Document)

      restored = transformer.to_core_model(mirror)
      expect(restored).to be_a(Ceradoc::CoreModel::DocumentElement)
      expect(restored.title).to eq('Test')
    end
  end

  describe 'JSON round-trip' do
    it 'serializes and deserializes through JSON' do
      original = Ceradoc::CoreModel::DocumentElement.new(
        title: 'JSON Round Trip',
        children: [
          Ceradoc::CoreModel::SectionElement.new(
            title: 'Intro',
            level: 1,
            id: 'intro',
            children: [
              Ceradoc::CoreModel::ParagraphBlock.new(content: 'Hello')
            ]
          )
        ]
      )

      json = Ceradoc::Mirror.to_json(original, pretty: true)
      parsed = JSON.parse(json)

      # Reconstruct from JSON
      mirror_node = Ceradoc::Mirror.from_hash(parsed)
      expect(mirror_node).to be_a(Ceradoc::Mirror::Node::Document)
      expect(mirror_node.attrs.title).to eq('JSON Round Trip')
    end
  end

  describe 'with AsciiDoc', if: Gem.loaded_specs.key?('ceradoc-adoc') do
    before do
      require 'ceradoc/asciidoc'
    end

    it 'transforms a complete AsciiDoc document to mirror JSON' do
      adoc = <<~ADOC
        = Integration Test
        Author Name

        == Introduction

        This has *bold* and _italic_ text.

        === Details

        [source,ruby]
        ----
        def hello
          puts "world"
        end
        ----

        * Item one
        * Item two

        NOTE: Pay attention to this.
      ADOC

      doc = Ceradoc.parse(adoc, format: :asciidoc)
      mirror = Ceradoc::Mirror.transform(doc)

      expect(mirror).to be_a(Ceradoc::Mirror::Node::Document)
      expect(mirror.attrs.title).to eq('Integration Test')

      json = JSON.pretty_generate(mirror.to_hash)
      parsed = JSON.parse(json)
      expect(parsed['type']).to eq('doc')
      expect(parsed['content'].length).to be >= 2

      sections = parsed['content'].select { |c| c['type'] == 'section' }
      expect(sections.length).to be >= 1
    end
  end
end
