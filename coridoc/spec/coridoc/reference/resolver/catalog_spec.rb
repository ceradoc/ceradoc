# frozen_string_literal: true

require 'spec_helper'
require 'coridoc/reference'

RSpec.describe Coridoc::Reference::Resolver::Catalog do
  let(:target) do
    Coridoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: [])
  end

  let(:document) do
    Coridoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'Doc',
      children: [target]
    )
  end

  let(:catalog) { Coridoc::Reference::Catalog::Local.from_doc(document) }

  let(:edge) do
    Coridoc::Reference::Edge.build(
      kind: :navigation,
      address: Coridoc::Reference::Address.parse('sec-3')
    )
  end

  describe '#resolve (resolved case)' do
    it 'returns Resolved when catalog knows the address' do
      resolver = described_class.new(catalog: catalog)
      result = resolver.resolve(edge)
      expect(result).to be_a(Coridoc::Reference::Result::Resolved)
      expect(result.target).to be(target)
    end
  end

  describe '#resolve (missing case)' do
    let(:missing_edge) do
      Coridoc::Reference::Edge.build(
        kind: :navigation,
        address: Coridoc::Reference::Address.parse('missing')
      )
    end

    it 'returns Missing by default' do
      resolver = described_class.new(catalog: catalog, missing: :warn)
      result = resolver.resolve(missing_edge)
      expect(result).to be_a(Coridoc::Reference::Result::Missing)
    end

    it 'raises when missing: :error' do
      resolver = described_class.new(catalog: catalog, missing: :error)
      expect { resolver.resolve(missing_edge) }
        .to raise_error(Coridoc::Reference::MissingReferenceError)
    end
  end

  describe '#resolve (ambiguous case)' do
    # One setup hash keeps the candidate identities stable within an
    # example (the catalog must return the very instance asserted on).
    let(:ambiguous_setup) do
      dup_a = Coridoc::CoreModel::SectionElement.new(id: 'shared', title: 'A', level: 1, children: [])
      dup_b = Coridoc::CoreModel::SectionElement.new(id: 'shared', title: 'B', level: 1, children: [])
      doc_a = Coridoc::CoreModel::DocumentElement.new(id: 'a', title: 'A', children: [dup_a])
      doc_b = Coridoc::CoreModel::DocumentElement.new(id: 'b', title: 'B', children: [dup_b])
      {
        dup_a: dup_a,
        composite: Coridoc::Reference::Catalog::Composite.new(
          Coridoc::Reference::Catalog::Local.from_doc(doc_a),
          Coridoc::Reference::Catalog::Local.from_doc(doc_b)
        )
      }
    end
    let(:composite) { ambiguous_setup[:composite] }
    let(:ambiguous_edge) do
      Coridoc::Reference::Edge.build(
        kind: :navigation,
        address: Coridoc::Reference::Address.parse('shared')
      )
    end

    it 'warns and resolves to the first candidate when ambiguous: :disambiguate' do
      resolver = described_class.new(catalog: composite, ambiguous: :disambiguate)
      result = nil
      expect { result = resolver.resolve(ambiguous_edge) }.to output(/shared/).to_stderr
      expect(result).to be_a(Coridoc::Reference::Result::Resolved)
      expect(result.target).to be(ambiguous_setup[:dup_a])
    end

    it 'returns Resolved with first when ambiguous: :first' do
      resolver = described_class.new(catalog: composite, ambiguous: :first)
      result = resolver.resolve(ambiguous_edge)
      expect(result).to be_a(Coridoc::Reference::Result::Resolved)
      expect(result.target).to be(ambiguous_setup[:dup_a])
    end

    it 'raises when ambiguous: :error' do
      resolver = described_class.new(catalog: composite, ambiguous: :error)
      expect { resolver.resolve(ambiguous_edge) }
        .to raise_error(Coridoc::Reference::AmbiguousReferenceError)
    end
  end

  describe '#resolve (scheme mismatch)' do
    it 'returns Missing when catalog does not recognize the scheme' do
      url_edge = Coridoc::Reference::Edge.build(
        kind: :link,
        address: Coridoc::Reference::Address.parse('https://example.com')
      )
      resolver = described_class.new(catalog: catalog)
      result = resolver.resolve(url_edge)
      expect(result).to be_a(Coridoc::Reference::Result::Missing)
    end
  end
end
