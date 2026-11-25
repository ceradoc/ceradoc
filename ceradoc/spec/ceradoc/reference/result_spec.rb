# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Result do
  let(:edge) do
    Ceradoc::Reference::Edge.build(
      kind: :navigation,
      address: Ceradoc::Reference::Address.parse('sec-3')
    )
  end

  let(:address) { edge.address }
  let(:target) { Ceradoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: []) }

  describe Ceradoc::Reference::Result::Resolved do
    it 'carries the target' do
      result = described_class.build(edge: edge, address: address, target: target)
      expect(result).to be_resolved
      expect(result.target).to be(target)
      expect(result.edge).to be(edge)
      expect(result.address).to eq(address)
    end
  end

  describe Ceradoc::Reference::Result::Ambiguous do
    it 'carries multiple candidates' do
      other = Ceradoc::CoreModel::SectionElement.new(id: 'dup', title: 'Dup', level: 1, children: [])
      result = described_class.build(edge: edge, address: address, candidates: [target, other])
      expect(result).to be_ambiguous
      expect(result.candidates.size).to eq(2)
    end
  end

  describe Ceradoc::Reference::Result::Missing do
    it 'carries the address' do
      result = described_class.build(edge: edge, address: address)
      expect(result).to be_missing
      expect(result.address).to eq(address)
    end
  end

  describe 'pattern matching' do
    it 'matches Resolved' do
      result = Ceradoc::Reference::Result::Resolved.build(
        edge: edge, address: address, target: target
      )
      matched = case result
                in Ceradoc::Reference::Result::Resolved => r then r.target
                else nil
                end
      expect(matched).to be(target)
    end

    it 'matches Missing' do
      result = Ceradoc::Reference::Result::Missing.build(edge: edge, address: address)
      matched = case result
                in Ceradoc::Reference::Result::Missing => m then m.address
                else nil
                end
      expect(matched).to eq(address)
    end
  end
end
