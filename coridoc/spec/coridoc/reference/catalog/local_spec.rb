# frozen_string_literal: true

require 'spec_helper'
require 'coridoc/reference'

RSpec.describe Coridoc::Reference::Catalog::Local do
  let(:section) do
    Coridoc::CoreModel::SectionElement.new(
      id: 'sec-3',
      title: 'Section 3',
      level: 1,
      children: []
    )
  end

  let(:other_section) do
    Coridoc::CoreModel::SectionElement.new(
      id: 'intro',
      title: 'Intro',
      level: 1,
      children: []
    )
  end

  let(:document) do
    Coridoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'The Doc',
      children: [section, other_section]
    )
  end

  describe '.from_doc' do
    it 'indexes anchors for every node with an id' do
      catalog = described_class.from_doc(document)
      expect(catalog.lookup(Coridoc::Reference::Address.parse('sec-3')))
        .to be(section)
      expect(catalog.lookup(Coridoc::Reference::Address.parse('intro')))
        .to be(other_section)
    end

    it 'indexes the document root by path when path is given' do
      catalog = described_class.from_doc(document, path: 'ELF-5005-1')
      expect(catalog.lookup(Coridoc::Reference::Address.parse('ELF-5005-1')))
        .to be(document)
    end

    it 'indexes the document root as scoped_path when path contains a colon' do
      catalog = described_class.from_doc(document, path: 'ELF:5005:1')
      expect(catalog.lookup(Coridoc::Reference::Address.parse('ELF:5005:1')))
        .to be(document)
    end

    it 'indexes the document root by its own id as an anchor' do
      catalog = described_class.from_doc(document, path: 'ELF-5005-1')
      # The doc's own id "doc" should be indexed (since the doc has an id).
      expect(catalog.lookup(Coridoc::Reference::Address.parse('doc')))
        .to be(document)
    end

    it 'returns all candidates for duplicate ids within one document' do
      dup_a = Coridoc::CoreModel::SectionElement.new(id: 'shared', title: 'A', level: 1, children: [])
      dup_b = Coridoc::CoreModel::SectionElement.new(id: 'shared', title: 'B', level: 2, children: [])
      doc = Coridoc::CoreModel::DocumentElement.new(
        id: 'doc', title: 'Doc', children: [dup_a, dup_b]
      )
      catalog = described_class.from_doc(doc)
      result = catalog.lookup(Coridoc::Reference::Address.parse('shared'))
      expect(result).to eq([dup_a, dup_b])
      expect(catalog.ambiguous?(Coridoc::Reference::Address.parse('shared'))).to be(true)
    end

    it 'indexes deeply nested sections' do
      leaf = Coridoc::CoreModel::SectionElement.new(id: 'deep', title: 'Deep', level: 3, children: [])
      mid = Coridoc::CoreModel::SectionElement.new(id: 'mid', title: 'Mid', level: 2, children: [leaf])
      top = Coridoc::CoreModel::SectionElement.new(id: 'top', title: 'Top', level: 1, children: [mid])
      doc = Coridoc::CoreModel::DocumentElement.new(id: 'doc', title: 'Doc', children: [top])
      catalog = described_class.from_doc(doc)
      expect(catalog.lookup(Coridoc::Reference::Address.parse('deep'))).to be(leaf)
    end

    it 'returns nil for unknown anchor' do
      catalog = described_class.from_doc(document)
      expect(catalog.lookup(Coridoc::Reference::Address.parse('missing')))
        .to be_nil
    end
  end

  describe '#recognizes_scheme?' do
    it 'recognizes anchor always' do
      catalog = described_class.from_doc(document)
      expect(catalog.recognizes_scheme?(:anchor)).to be(true)
    end

    it 'recognizes path when document_path is set' do
      catalog = described_class.from_doc(document, path: 'ELF-5005-1')
      expect(catalog.recognizes_scheme?(:path)).to be(true)
    end

    it 'recognizes scoped_path when document_path has a colon' do
      catalog = described_class.from_doc(document, path: 'ELF:5005:1')
      expect(catalog.recognizes_scheme?(:scoped_path)).to be(true)
    end

    it 'does not recognize url by default' do
      catalog = described_class.from_doc(document)
      expect(catalog.recognizes_scheme?(:url)).to be(false)
    end
  end

  describe '#each_pair' do
    it 'enumerates all indexed pairs' do
      catalog = described_class.from_doc(document, path: 'ELF-5005-1')
      pairs = catalog.each_pair.to_a
      targets = pairs.map { |_, content| content }
      expect(targets).to include(document, section, other_section)
    end
  end
end
