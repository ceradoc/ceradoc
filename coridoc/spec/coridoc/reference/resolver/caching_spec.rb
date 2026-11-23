# frozen_string_literal: true

require 'spec_helper'
require 'coridoc/reference'

RSpec.describe Coridoc::Reference::Resolver::Caching do
  let(:target) do
    Coridoc::CoreModel::SectionElement.new(id: 'a', title: 'A', level: 1, children: [])
  end
  let(:address) { Coridoc::Reference::Address.parse('anchor-a') }

  let(:document) do
    Coridoc::CoreModel::DocumentElement.new(id: 'doc', title: 'Doc', children: [target])
  end
  let(:catalog) { Coridoc::Reference::Catalog::Local.from_doc(document) }
  let(:inner) { Coridoc::Reference::Resolver::Catalog.new(catalog: catalog) }

  let(:edge) do
    Coridoc::Reference::Edge.build(kind: :navigation, address: address)
  end

  it 'memoizes by address' do
    caching = described_class.new(inner: inner)
    first = caching.resolve(edge)
    second = caching.resolve(edge)
    expect(first).to be(second)
    expect(caching.size).to eq(1)
  end

  it 'clears the cache on #clear!' do
    caching = described_class.new(inner: inner)
    caching.resolve(edge)
    expect(caching.size).to eq(1)
    caching.clear!
    expect(caching.size).to eq(0)
  end

  it 'returns a Result embedding the asking edge when addresses collide' do
    caching = described_class.new(inner: inner)
    nav_edge = Coridoc::Reference::Edge.build(
      kind: :navigation, address: address, label: 'first'
    )
    citation_edge = Coridoc::Reference::Edge.build(
      kind: :citation, address: address, label: 'second'
    )
    caching.resolve(nav_edge)
    second = caching.resolve(citation_edge)
    expect(caching.size).to eq(1)
    expect(second.edge.kind).to eq('citation')
    expect(second.edge.label).to eq('second')
  end
end
