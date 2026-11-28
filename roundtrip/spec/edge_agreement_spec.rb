# frozen_string_literal: true

require_relative 'spec_helper'
require 'ceradoc/reference'

# Phase-1 EdgeSearch retirement validator (#382).
#
# Edges are first-class: reference-carrying nodes declare their Edge in
# the +edges+ attribute (CoreModel::EdgeCarrier) and keep it in sync
# with their fields. Reference::Validation and Reference::Resolution
# consume the declared attribute — extraction is no longer on any
# production path.
#
# This suite keeps the phase-1 extraction alive as an INDEPENDENT
# derivation and asserts, across the whole roundtrip corpus, that both
# derivations agree on every carrier node of every parsed document.
# Drift on either side fails here.
RSpec.describe 'declared edges agree with EdgeSearch extraction' do
  wanted = ENV['ROUNDTRIP_FORMAT']&.to_sym

  Ceradoc::Roundtrip::FORMATS.each do |format|
    next if wanted && wanted != format

    describe format.to_s do
      Ceradoc::Roundtrip::Corpus.cases(format: format).each do |kase|
        it kase.id do
          core = Ceradoc.parse(kase.text, format: kase.format)
          divergences = []

          Ceradoc::Reference::EdgeSearch.walk(core) do |node|
            next unless node.is_a?(Ceradoc::CoreModel::EdgeCarrier)

            expected = extracted_edges(node)
            divergences << [node.class.name, node.id, node.edges, expected] if
              node.edges != expected
          end

          expect(divergences).to eq([]), -> { format_divergences(kase, divergences) }
        end
      end
    end
  end

  # Extraction-derived edges. A malformed reference target (empty or
  # unparseable) raises inside the phase-1 extractor; the declared
  # derivation answers "no edge" for the same input — that contract is
  # part of the agreement, not a divergence.
  def extracted_edges(node)
    Ceradoc::Reference::EdgeSearch.edges_for(node)
  rescue Ceradoc::Reference::Address::ParseError
    []
  end

  def format_divergences(kase, divergences)
    first = divergences.first
    "first divergence in #{kase.id}: #{first[0]}##{first[1].inspect} " \
      "declared=#{first[2].map(&:to_s).inspect} extracted=#{first[3].map(&:to_s).inspect}"
  end
end
