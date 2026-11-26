# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Catalog::Remote do
  # Real fetcher with a recorded call log — proves laziness (no fetch
  # at construction, one fetch per lookup) without message doubles.
  def fetcher_class
    Class.new do
      attr_reader :calls

      def initialize(table)
        @table = table
        @calls = []
      end

      def fetch(address)
        @calls << address
        @table[address]
      end
    end
  end

  let(:remote_doc) do
    Ceradoc::CoreModel::SectionElement.new(
      id: 'remote-sec', title: 'Remote', level: 1, children: []
    )
  end

  let(:url_address) do
    Ceradoc::Reference::Address.parse('https://example.org/docs/elf.html')
  end
  let(:doi_address) { Ceradoc::Reference::Address.parse('10.1234/abc') }
  let(:anchor_address) { Ceradoc::Reference::Address.parse('somewhere') }

  let(:table) { { url_address => remote_doc } }
  let(:fetcher) { fetcher_class.new(table) }

  let(:remote) do
    described_class.new(schemes: %i[url], fetcher: fetcher)
  end

  describe '#lookup' do
    it 'fetches through the fetcher for handled schemes' do
      expect(remote.lookup(url_address)).to be(remote_doc)
    end

    it 'returns nil when the fetcher misses' do
      miss = Ceradoc::Reference::Address.parse('https://example.org/none.html')

      expect(remote.lookup(miss)).to be_nil
    end

    it 'does not fetch schemes outside its scheme set' do
      expect(remote.lookup(doi_address)).to be_nil
      expect(fetcher.calls).to be_empty
    end

    it 'fetches lazily — nothing at construction' do
      described_class.new(schemes: %i[url], fetcher: fetcher)

      expect(fetcher.calls).to be_empty
    end

    it 'asks the fetcher once per lookup' do
      remote.lookup(url_address)

      expect(fetcher.calls).to eq([url_address])
    end
  end

  describe '#recognizes_scheme?' do
    it 'recognizes exactly its scheme set' do
      expect(remote.recognizes_scheme?(:url)).to be(true)
      expect(remote.recognizes_scheme?(:doi)).to be(false)
      expect(remote.recognizes_scheme?(:anchor)).to be(false)
    end

    it 'accepts a single scheme symbol' do
      single = described_class.new(schemes: :url, fetcher: fetcher)

      expect(single.recognizes_scheme?(:url)).to be(true)
    end
  end

  describe '#each_pair' do
    it 'enumerates nothing — a lazy catalog has no local pairs' do
      expect(remote.each_pair.to_a).to eq([])
    end
  end

  describe 'composite resolution over local + remote' do
    # Plain method — keeps the memoized-helper count down.
    def local_doc
      Ceradoc::CoreModel::DocumentElement.new(
        id: 'local-doc', title: 'Local',
        children: [
          Ceradoc::CoreModel::SectionElement.new(
            id: 'local-sec', title: 'Local Sec', level: 1, children: []
          )
        ]
      )
    end

    it 'finds content in either layer' do
      document = local_doc
      local = Ceradoc::Reference::Catalog::Local.from_doc(document)
      composite = Ceradoc::Reference::Catalog::Composite.new(local, remote)

      expect(composite.lookup(Ceradoc::Reference::Address.parse('local-sec')))
        .to be(document.children.first)
      expect(composite.lookup(url_address)).to be(remote_doc)
    end

    it 'surfaces Deferred for schemes no child handles' do
      local = Ceradoc::Reference::Catalog::Local.from_doc(local_doc)
      remote_only_url = described_class.new(schemes: %i[url], fetcher: fetcher)
      resolver = Ceradoc::Reference::Resolver::Catalog.new(
        catalog: Ceradoc::Reference::Catalog::Composite.new(local, remote_only_url),
        unrecognized: :defer
      )
      edge = Ceradoc::Reference::Edge.build(kind: :citation, address: doi_address)

      result = resolver.resolve(edge)

      expect(result).to be_a(Ceradoc::Reference::Result::Deferred)
      expect(result.reason).to include('doi')
    end
  end
end
