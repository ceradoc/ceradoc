# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Validation do
  def section(id, title, children = [])
    Ceradoc::CoreModel::SectionElement.new(
      id: id, title: title, level: 1, children: children
    )
  end

  let(:local_section) { section('sec-target', 'Target Section') }

  let(:document) do
    Ceradoc::CoreModel::DocumentElement.new(
      id: 'main-doc',
      title: 'Main',
      children: [
        section(
          'sec-nav',
          'Navigation',
          [
            Ceradoc::CoreModel::CrossReferenceElement.new(
              target: 'sec-target', content: 'to target'
            ),
            Ceradoc::CoreModel::CrossReferenceElement.new(
              target: 'no-such-anchor', content: 'to nowhere'
            ),
            Ceradoc::CoreModel::LinkElement.new(
              target: 'https://example.org/ok', content: 'external'
            ),
            Ceradoc::CoreModel::Image.new(src: 'missing-image.png', alt: 'Alt')
          ]
        ),
        section(
          'sec-inc',
          'Includes',
          [Ceradoc::CoreModel::Include.new(target: 'also-missing.adoc')]
        ),
        local_section
      ]
    )
  end

  let(:catalog) do
    Ceradoc::Reference::Catalog::Local.from_doc(document, path: 'MAIN-1')
  end

  def diagnostics_by_code(report)
    report.diagnostics.group_by(&:code)
  end

  describe '.run' do
    let(:report) { described_class.run(document, catalog: catalog) }

    it 'emits one entry per edge — resolved and unresolved alike' do
      # sec-nav: xref, xref, link, image; sec-inc: include.
      expect(report.size).to eq(5)
    end

    it 'does not mutate the document' do
      described_class.run(document, catalog: catalog)

      expect(document.children.size).to eq(3)
      expect(document.children[0].children.size).to eq(4)
    end

    it 'keeps resolved edges out of the diagnostics' do
      resolved = report.entries.select { |e| e.result.resolved? }

      expect(resolved.map { |e| e.edge.address.target }).to eq(['sec-target'])
      expect(resolved.map(&:diagnostic)).to all(be_nil)
    end

    # The link targets a URL and the Local catalog handles no url scheme
    # — reported Missing, positioned, typed like any other unresolved edge.
    it 'reports unresolved edges as missing with origin info' do
      missing = report.unresolved

      expect(missing.size).to eq(4)
      expect(missing.map { |e| e.edge.address.target })
        .to contain_exactly('no-such-anchor', 'https://example.org/ok',
                            'missing-image.png', 'also-missing.adoc')
    end

    it 'positions missing edges at their source node path' do
      xref_entry = report.unresolved.find do |entry|
        entry.edge.address.target == 'no-such-anchor'
      end
      origin = xref_entry.diagnostic.origin

      expect(origin.node_path)
        .to eq('DocumentElement#main-doc > SectionElement#sec-nav > ' \
               'CrossReferenceElement')
      expect(origin.node_id).to be_nil
      expect(origin.to_s).to include('SectionElement#sec-nav')
    end

    it 'types missing diagnostics per edge kind' do
      codes = diagnostics_by_code(report).keys

      expect(codes).to contain_exactly(
        'missing_navigation', 'missing_link', 'missing_image_ref',
        'missing_include'
      )
    end

    it 'carries the target address on every diagnostic' do
      report.diagnostics.each do |diagnostic|
        expect(diagnostic.address).to be_a(Ceradoc::Reference::Address)
      end
    end

    it 'severities: missing is an error, report is not ok' do
      expect(report.diagnostics).to all(have_attributes(severity: 'error'))
      expect(report.errors.size).to eq(4)
      expect(report.warnings).to eq([])
      expect(report.ok?).to be(false)
    end

    it 'renders diagnostics for humans' do
      text = report.diagnostics.first.to_s

      expect(text).to match(/\ADocumentElement#main-doc > .*\[missing_/)
    end
  end

  describe 'ambiguous candidates' do
    let(:dupe_document) do
      Ceradoc::CoreModel::DocumentElement.new(
        id: 'dupe-doc', title: 'Dupes',
        children: [
          section('twice', 'First'),
          section('twice', 'Second'),
          section(
            'sec-ref', 'Ref',
            [Ceradoc::CoreModel::CrossReferenceElement.new(
              target: 'twice', content: 'ambiguous ref'
            )]
          )
        ]
      )
    end

    let(:report) do
      catalog = Ceradoc::Reference::Catalog::Local.from_doc(dupe_document)
      described_class.run(dupe_document, catalog: catalog)
    end

    it 'reports ambiguous edges as warnings with candidates' do
      expect(report.warnings.size).to eq(1)

      diagnostic = report.warnings.first
      expect(diagnostic.code).to eq('ambiguous_navigation')
      expect(diagnostic.message).to include('2 candidates')
      expect(diagnostic.origin.node_id).to be_nil
    end

    it 'stays ok? — ambiguity is a warning, not a failure' do
      expect(report.errors).to eq([])
      expect(report.ok?).to be(true)
    end
  end

  describe 'resolver override' do
    let(:fetcher_class) do
      Class.new do
        def initialize(table)
          @table = table
        end

        def fetch(address)
          @table[address]
        end
      end
    end

    it 'surfaces Deferred diagnostics for unresolvable schemes' do
      remote = Ceradoc::Reference::Catalog::Remote.new(
        schemes: %i[url], fetcher: fetcher_class.new({})
      )
      resolver = Ceradoc::Reference::Resolver::Catalog.new(
        catalog: remote, unrecognized: :defer
      )
      report = described_class.run(
        document, catalog: catalog, resolver: resolver
      )

      deferred = report.deferred
      expect(deferred.size).to eq(4)

      diagnostic = deferred.first.diagnostic
      expect(diagnostic.code).to eq('deferred_navigation')
      expect(diagnostic.severity).to eq('info')
      expect(diagnostic.message).to include('scheme')
    end

    it 'resolves through a chain of resolvers first-hit-wins' do
      remote = Ceradoc::Reference::Catalog::Remote.new(
        schemes: %i[url],
        fetcher: fetcher_class.new(
          Ceradoc::Reference::Address.parse('https://example.org/ok') => local_section
        )
      )
      local_resolver = Ceradoc::Reference::Resolver::Catalog.new(catalog: catalog)
      remote_resolver = Ceradoc::Reference::Resolver::Catalog.new(
        catalog: remote, unrecognized: :defer
      )
      chain = Ceradoc::Reference::Resolver::Chain.new(local_resolver, remote_resolver)

      report = described_class.run(document, catalog: catalog, resolver: chain)
      link_entry = report.entries.find { |e| e.edge.kind == 'link' }

      expect(link_entry.result).to be_resolved
      expect(link_entry.result.target).to be(local_section)
    end
  end

  describe '.validate convenience' do
    it 'is exposed on the Reference module' do
      report = Ceradoc::Reference.validate(document, catalog: catalog)

      expect(report).to be_a(Ceradoc::Reference::Validation::Report)
    end
  end
end
