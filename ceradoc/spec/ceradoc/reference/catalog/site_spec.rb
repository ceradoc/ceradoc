# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Catalog::Site do
  def section(id, title)
    Ceradoc::CoreModel::SectionElement.new(
      id: id, title: title, level: 1, children: []
    )
  end

  def doc(id, title, children)
    Ceradoc::CoreModel::DocumentElement.new(
      id: id, title: title, children: children
    )
  end

  let(:doc_elf_first) do
    doc('elf-1', 'ELF 5005 part 1', [section('sec-5005-1', 'Sec 5005/1')])
  end
  let(:doc_elf_second) do
    doc('elf-2', 'ELF 5005 part 2', [section('sec-5005-2', 'Sec 5005/2')])
  end
  let(:doc_other) do
    doc('other', 'Other component', [section('sec-other', 'Sec other')])
  end

  let(:collection) do
    catalog = Ceradoc::Reference::Catalog::Collection.new
    catalog.ingest(doc_elf_first, path: 'ELF:5005:1', origin: '5005-1.adoc')
    catalog.ingest(doc_elf_second, path: 'ELF:5005:2', origin: '5005-2.adoc')
    catalog.ingest(doc_other, path: 'NIST:80053:4', origin: '800-53.adoc')
    catalog
  end

  context 'with component/version/module layers' do
    let(:site) do
      described_class.new(
        collection: collection, component: 'ELF', version: '5005',
        module_name: '1'
      )
    end

    it 'resolves scoped addresses inside its scope' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('ELF:5005:1')))
        .to be(doc_elf_first)
      expect(site.lookup(Ceradoc::Reference::Address.parse('ELF:5005:1#sec-5005-1')))
        .to be_nil # fragment locality is not indexed separately
    end

    it 'misses addresses outside any layer' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('ELF:5005:2'))).to be_nil
      expect(site.lookup(Ceradoc::Reference::Address.parse('NIST:80053:4'))).to be_nil
    end

    it 'covers only matching identities' do
      expect(site.covers_identity?(Ceradoc::Reference::Address.parse('ELF:5005:1')))
        .to be(true)
      expect(site.covers_identity?(Ceradoc::Reference::Address.parse('ELF:5005:2')))
        .to be(false)
      expect(site.covers_identity?(Ceradoc::Reference::Address.parse('NIST:80053:4')))
        .to be(false)
    end

    it 'qualifies bare scoped targets with the site component' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('5005:1', hint: :path)))
        .to be(doc_elf_first)
    end

    it 'exposes only the covered documents' do
      expect(site.documents).to eq([doc_elf_first])
    end
  end

  context 'with a path-identity corpus' do
    let(:path_collection) do
      catalog = Ceradoc::Reference::Catalog::Collection.new
      catalog.ingest(doc_elf_first, path: 'ELF-5005-1', origin: '5005-1.adoc')
      catalog.ingest(doc_other, path: 'NIST-800-53-4', origin: '800-53.adoc')
      catalog
    end
    let(:site) do
      described_class.new(collection: path_collection, component: 'ELF')
    end

    it 'decomposes dash-separated identities' do
      expect(site.covers_identity?(Ceradoc::Reference::Address.parse('ELF-5005-1')))
        .to be(true)
      expect(site.covers_identity?(Ceradoc::Reference::Address.parse('NIST-800-53-4')))
        .to be(false)
    end

    it 'qualifies bare path targets with the site component' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('5005-1', hint: :path)))
        .to be(doc_elf_first)
    end

    it 'searches anchors across covered sources without qualifying' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('sec-5005-1')))
        .to be(doc_elf_first.children.first)
    end

    it 'misses anchors that live outside the scope' do
      expect(site.lookup(Ceradoc::Reference::Address.parse('sec-other'))).to be_nil
    end
  end

  context 'without scoping layers' do
    let(:site) { described_class.new(collection: collection) }

    it 'covers everything and behaves like the collection' do
      expect(site.covers_identity?(nil)).to be(true)
      expect(site.lookup(Ceradoc::Reference::Address.parse('NIST:80053:4')))
        .to be(doc_other)
    end
  end

  describe 'scoping is a filtered view, not new storage' do
    let(:site) do
      described_class.new(collection: collection, component: 'ELF',
                          version: '5005', module_name: '1')
    end

    it 'yields pairs only from covered sources' do
      addresses = site.each_pair.map { |addr, _| addr }

      expect(addresses).to all(satisfy do |addr|
        addr.scheme != 'scoped_path' || addr.scope == 'ELF'
      end)
    end

    it 'returns the very objects stored by the collection' do
      hit = site.lookup(Ceradoc::Reference::Address.parse('ELF:5005:1'))

      expect(hit).to be(doc_elf_first)
    end

    it 'does not recognize schemes its sources lack' do
      expect(site.recognizes_scheme?(:url)).to be(false)
      expect(site.recognizes_scheme?(:scoped_path)).to be(true)
    end
  end

  describe 'empty collection' do
    it 'resolves nothing' do
      site = described_class.new(
        collection: Ceradoc::Reference::Catalog::Collection.new,
        component: 'ELF'
      )

      expect(site.lookup(Ceradoc::Reference::Address.parse('ELF:5005:1'))).to be_nil
    end
  end
end
