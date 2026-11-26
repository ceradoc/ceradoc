# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Catalog::Collection do
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

  let(:doc_a) do
    doc('doc-a', 'A', [section('sec-a', 'Sec A'), section('shared', 'A shared')])
  end
  let(:doc_b) do
    doc('doc-b', 'B', [section('sec-b', 'Sec B'), section('shared', 'B shared')])
  end

  let(:collection) { described_class.new }

  describe '#ingest' do
    it 'indexes anchors across documents' do
      collection.ingest(doc_a, path: 'ELF-5005-1')
      collection.ingest(doc_b, path: 'ELF-5005-2')

      expect(collection.lookup(Ceradoc::Reference::Address.parse('sec-a')))
        .to be(doc_a.children.first)
      expect(collection.lookup(Ceradoc::Reference::Address.parse('sec-b')))
        .to be(doc_b.children.first)
    end

    it 'indexes the document root by its identity path' do
      collection.ingest(doc_a, path: 'ELF-5005-1')
      expect(collection.lookup(Ceradoc::Reference::Address.parse('ELF-5005-1')))
        .to be(doc_a)
    end

    it 'indexes scoped identities' do
      collection.ingest(doc_a, path: 'ELF:5005:1')
      expect(collection.lookup(Ceradoc::Reference::Address.parse('ELF:5005:1')))
        .to be(doc_a)
    end

    it 'records the origin per source' do
      collection.ingest(doc_a, path: 'ELF-5005-1', origin: 'sources/a.adoc')

      expect(collection.provenance(Ceradoc::Reference::Address.parse('sec-a')))
        .to eq(['sources/a.adoc'])
    end
  end

  describe 'duplicate identity merge' do
    before do
      collection.ingest(doc_a, path: 'ELF-5005-1', origin: 'first.adoc')
      collection.ingest(doc_b, path: 'ELF-5005-2', origin: 'second.adoc')
    end

    # Same-identity Content across sources ("shared" exists in both
    # docs): duplicates are kept, marked with provenance, and resolved
    # by lineage — the first-ingested source wins. Never fatal.
    it 'keeps both candidates with provenance' do
      address = Ceradoc::Reference::Address.parse('shared')

      expect(collection.entries(address).size).to eq(2)
      expect(collection.provenance(address)).to eq(%w[first.adoc second.adoc])
      expect(collection.duplicate?(address)).to be(true)
    end

    it 'resolves duplicates by lineage: first-ingested wins' do
      address = Ceradoc::Reference::Address.parse('shared')

      expect(collection.lookup(address)).to be(doc_a.children.last)
    end

    it 'never reports ambiguity — lineage decides' do
      expect(collection.ambiguous?(Ceradoc::Reference::Address.parse('shared')))
        .to be(false)
    end

    it 'merges same document identity across sources without clobbering' do
      clone = doc('doc-a', 'A again', [section('sec-a', 'Sec A again')])
      collection.ingest(clone, path: 'ELF-5005-1', origin: 'clone.adoc')

      expect(collection.lookup(Ceradoc::Reference::Address.parse('ELF-5005-1')))
        .to be(doc_a)
      expect(collection.provenance(Ceradoc::Reference::Address.parse('ELF-5005-1')))
        .to eq(%w[first.adoc clone.adoc])
    end

    it 'enumerates every duplicate pair' do
      address = Ceradoc::Reference::Address.parse('shared')
      pairs = collection.each_pair.select { |addr, _| addr == address }

      expect(pairs.size).to eq(2)
    end
  end

  describe '.from_documents' do
    it 'ingests bare documents and (document, path) pairs' do
      collection = described_class.from_documents(
        [doc_a, [doc_b, 'ELF-5005-2']]
      )

      expect(collection.sources.size).to eq(2)
      expect(collection.lookup(Ceradoc::Reference::Address.parse('ELF-5005-2')))
        .to be(doc_b)
    end
  end

  describe '#ingest_file' do
    it 'parses the file through the format registry and ingests it' do
      file = Tempfile.new(['spec', '.adoc'])
      begin
        file.write(<<~ADOC)
          = Spec Doc
          :docid: ELF-9999-9

          [[spec-target]]
          == Target Section

          Body text.
        ADOC
        file.close

        collection.ingest_file(file.path, document_path: 'ELF-9999-9')

        found = collection.lookup(Ceradoc::Reference::Address.parse('spec-target'))
        expect(found).to be_a(Ceradoc::CoreModel::SectionElement)
        expect(found.id).to eq('spec-target')
        expect(
          collection.provenance(Ceradoc::Reference::Address.parse('spec-target'))
        ).to eq([file.path])
      ensure
        file.unlink
      end
    end
  end

  describe '#recognizes_scheme?' do
    it 'recognizes anchor once any document is ingested' do
      expect(collection.recognizes_scheme?(:anchor)).to be(false)
      collection.ingest(doc_a)
      expect(collection.recognizes_scheme?(:anchor)).to be(true)
    end

    it 'recognizes path only when a source carries a path identity' do
      collection.ingest(doc_a)
      expect(collection.recognizes_scheme?(:path)).to be(false)

      collection.ingest(doc_b, path: 'ELF-5005-2')
      expect(collection.recognizes_scheme?(:path)).to be(true)
    end

    it 'recognizes scoped_path only when a source carries a scoped identity' do
      collection.ingest(doc_a, path: 'ELF:5005:1')
      expect(collection.recognizes_scheme?(:scoped_path)).to be(true)
    end
  end

  describe '#size' do
    it 'counts distinct addresses' do
      collection.ingest(doc_a, path: 'ELF-5005-1')
      collection.ingest(doc_b, path: 'ELF-5005-2')

      # doc-a: ELF-5005-1 + doc-a + sec-a + shared; doc-b the same —
      # "shared" counts once (7 distinct addresses).
      expect(collection.size).to eq(7)
    end
  end
end
