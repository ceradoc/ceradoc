# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc'

RSpec.describe Ceradoc::Pipeline do
  describe '.build' do
    it 'yields a fresh DocumentElement' do
      doc = described_class.build do |d|
        d.title = 'Hello'
      end
      expect(doc).to be_a(Ceradoc::CoreModel::DocumentElement)
      expect(doc.title).to eq('Hello')
    end
  end

  describe '.parse / .serialize round-trip' do
    it 'routes through the registered format' do
      adoc = "= Title\n\nbody"
      core = described_class.parse(adoc, format: :asciidoc)
      expect(core).to be_a(Ceradoc::CoreModel::Base)

      out = described_class.serialize(core, to: :asciidoc)
      expect(out).to include('Title')
      expect(out).to include('body')
    end
  end

  describe '.serialize (unresolved includes guard)' do
    let(:doc) do
      Ceradoc::CoreModel::DocumentElement.new(
        id: 'doc', title: 'Doc',
        children: [Ceradoc::CoreModel::Include.new(target: 'shared/common.adoc')]
      )
    end

    it 'serializes graph-mode documents to asciidoc (native include round-trip)' do
      expect { described_class.serialize(doc, to: :asciidoc) }.not_to raise_error
    end
  end

  describe '.convert' do
    it 'composes parse + serialize' do
      adoc = "= Hello\n\nWorld"
      out = described_class.convert(adoc, from: :asciidoc, to: :asciidoc)
      expect(out).to include('Hello')
    end

    # ceradoc/ceradoc#337: the CLI always forwards convert options (lang,
    # toc_levels, ... carry thor defaults), so serializers must accept an
    # options hash. The AsciiDoc facade previously had strict arity and
    # raised on every `convert -t adoc`.
    it 'converts to adoc with CLI-style options forwarded' do
      adoc = "= Hello\n\nWorld"
      out = described_class.convert(
        adoc, from: :asciidoc, to: :asciidoc,
              lang: 'en', toc_levels: 2, section_number_levels: 3,
              theme: :classic, asset_delivery: :embedded
      )
      expect(out).to include('Hello')
    end
  end

  describe '.to_core' do
    it 'returns CoreModel inputs unchanged' do
      doc = Ceradoc::CoreModel::DocumentElement.new
      expect(described_class.to_core(doc)).to be(doc)
    end
  end
end
