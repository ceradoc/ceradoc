# frozen_string_literal: true

require_relative 'spec_helper'
require 'ceradoc/mirror'

# The mirror lane of the standing round-trip property (#384): a CoreModel
# tree converts to the ProseMirror node layer and BACK with its meaning
# intact.
#
# Scope notes (each a documented, deliberate exclusion — not a pass):
# - `source_line` — parse bookkeeping, excluded by Projection everywhere.
# - `lines` — the parse-side source-line view; the mirror carries meaning
#   (children/content), not source splits. Verbatim content fidelity is
#   owned by the text-format fixed-point property of the Checker.
# - `constraint` — the ProseMirror mark model has no constrained/
#   unconstrained concept; the distinction is a ProseMirror-format
#   limitation (tracked in the mirror fidelity issue), not a mirror bug.
RSpec.describe 'Mirror round-trip fidelity' do
  let(:transformer) { Ceradoc::Mirror::Transformer.new }
  let(:ignored) { %i[source_line lines constraint] }

  it 'restores ids and flattened content through the header seam' do
    core = Ceradoc.parse("= Docker\n\nintro text\n", format: :asciidoc)
    restored = transformer.to_core_model(transformer.from_core_model(core))

    header = restored.children.first
    expect(header).to be_a(Ceradoc::CoreModel::HeaderElement)
    # the parser auto-slugs the header id; the mirror seam must carry it
    expect(header.id).to eq(core.children.first.id)
    expect(header.id).to eq('_docker')
    expect(header.content).to eq('Docker')
  end

  # Self-widening ratchet: every corpus sample that round-trips clean
  # today must STAY clean. The scan below runs the FULL corpus and
  # asserts a floor of clean samples, so the ratchet can only grow:
  # any reverse-fidelity regression (a once-clean sample drifting, or
  # a sample crashing mid-conversion) fails the lane.
  it 'round-trips corpus samples to meaning-equal trees' do
    clean = []
    Ceradoc::Roundtrip::Corpus.cases(format: :asciidoc).each do |kase|
      core = Ceradoc.parse(kase.text, format: :asciidoc)
      restored = transformer.to_core_model(transformer.from_core_model(core))

      path, left, right = Ceradoc::Roundtrip::Projection.first_difference(
        Ceradoc::Roundtrip::Projection.of(core, ignored: ignored),
        Ceradoc::Roundtrip::Projection.of(restored, ignored: ignored)
      )
      clean << [kase.id, path, left, right] if path.nil?
    rescue StandardError => e
      # A sample that raises mid-conversion is a fidelity failure of
      # its own (e.g. lutaml rejecting a mis-shaped collection) — name
      # it so the failure is actionable instead of a silent count drop.
      raise "#{kase.id} raised mid-conversion: #{e.class}: #{e.message[0, 120]}"
    end

    expect(clean.size).to be >= 6
  end
end
