# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Resolver::Chain do
  let(:target_a) do
    Ceradoc::CoreModel::SectionElement.new(id: 'a', title: 'A', level: 1, children: [])
  end
  let(:target_b) do
    Ceradoc::CoreModel::SectionElement.new(id: 'b', title: 'B', level: 1, children: [])
  end

  let(:address_a) { Ceradoc::Reference::Address.parse('anchor-a') }
  let(:address_b) { Ceradoc::Reference::Address.parse('anchor-b') }

  let(:resolver_a) do
    Ceradoc::Reference::Resolver::Catalog.new(catalog: catalog_a)
  end
  let(:resolver_b) do
    Ceradoc::Reference::Resolver::Catalog.new(catalog: catalog_b)
  end

  let(:chain) { described_class.new(resolver_a, resolver_b) }

  def fake_catalog_class
    Struct.new(:index, :schemes) do
      include Ceradoc::Reference::Catalog::Protocol

      def lookup(address)
        Array(index[address]).first
      end

      def each_pair(&block)
        index.each(&block) if block_given?
      end

      def recognizes_scheme?(scheme)
        Array(schemes).include?(scheme.to_sym)
      end
    end
  end

  # Real resolver that records every edge it is asked about — proves
  # short-circuiting without message-expectation doubles.
  def recording_resolver_class
    Class.new(Ceradoc::Reference::Resolver::Base) do
      attr_reader :calls

      def initialize(result:)
        super()
        @result = result
        @calls = []
      end

      def resolve(edge)
        @calls << edge
        @result
      end
    end
  end

  def catalog_a
    fake_catalog_class.new({ address_a => target_a }, [:anchor])
  end

  def catalog_b
    fake_catalog_class.new({ address_b => target_b }, [:anchor])
  end

  it 'returns Resolved from the first resolver when it has the target' do
    edge = Ceradoc::Reference::Edge.build(kind: :navigation, address: address_a)
    result = chain.resolve(edge)
    expect(result).to be_a(Ceradoc::Reference::Result::Resolved)
    expect(result.target).to be(target_a)
  end

  it 'falls through to the second resolver when first misses' do
    edge = Ceradoc::Reference::Edge.build(kind: :navigation, address: address_b)
    result = chain.resolve(edge)
    expect(result).to be_a(Ceradoc::Reference::Result::Resolved)
    expect(result.target).to be(target_b)
  end

  it 'returns Missing when no resolver knows the address' do
    edge = Ceradoc::Reference::Edge.build(
      kind: :navigation,
      address: Ceradoc::Reference::Address.parse('unknown')
    )
    result = chain.resolve(edge)
    expect(result).to be_a(Ceradoc::Reference::Result::Missing)
  end

  it 'does not consult the second resolver when the first resolves' do
    edge = Ceradoc::Reference::Edge.build(kind: :navigation, address: address_a)
    resolved = Ceradoc::Reference::Result::Resolved.build(
      edge: edge, address: address_a, target: target_a
    )
    first = recording_resolver_class.new(result: resolved)
    second = recording_resolver_class.new(
      result: Ceradoc::Reference::Result::Missing.build(edge: edge, address: address_a)
    )
    described_class.new(first, second).resolve(edge)
    expect(first.calls.size).to eq(1)
    expect(second.calls).to be_empty
  end

  it 'short-circuits on Ambiguous without consulting later resolvers' do
    edge = Ceradoc::Reference::Edge.build(kind: :navigation, address: address_a)
    ambiguous = Ceradoc::Reference::Result::Ambiguous.build(
      edge: edge, address: address_a, candidates: [target_a, target_b]
    )
    first = recording_resolver_class.new(result: ambiguous)
    second = recording_resolver_class.new(
      result: Ceradoc::Reference::Result::Missing.build(edge: edge, address: address_a)
    )
    result = described_class.new(first, second).resolve(edge)
    expect(result).to be(ambiguous)
    expect(second.calls).to be_empty
  end
end
