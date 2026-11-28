# frozen_string_literal: true

require_relative 'spec_helper'

# The sealed parity vectors, run against the Ruby lane
# (docs/_references/parity-vectors.adoc). Byte equality is the hard,
# un-ratcheted property; structural equality and the producer gaps are
# bistable ratchets, the KnownFailures pattern applied to machinery.
#
# Run one source format only with
#   ROUNDTRIP_FORMAT=markdown bundle exec rspec roundtrip/spec/vector_spec.rb
RSpec.describe 'Parity vectors' do
  vectors = Ceradoc::Roundtrip::Vector::Store.load
  loader_gaps = Ceradoc::Roundtrip::Vector::Gaps.load(Ceradoc::Roundtrip::Vector::Store::LOADER_GAPS)
  producer_gaps = Ceradoc::Roundtrip::Vector::Gaps.load(Ceradoc::Roundtrip::Vector::Store::PRODUCER_GAPS)

  wanted = ENV['ROUNDTRIP_FORMAT']&.to_sym
  selected = vectors.vectors.select { |v| wanted.nil? || v.format == wanted }
  results = {}

  gap_id = ->(vector, fmt) { "#{vector.case_id}@#{vector.layer}:#{fmt}" }
  in_wanted_format = ->(id) { wanted.nil? || id.start_with?("#{wanted}:") }

  describe 'manifest integrity' do
    it 'matches the checksum of every listed file' do
      expect(vectors.checksum_mismatches).to eq([])
    end

    it 'seals at least one vector for every layer and format' do
      sealed = selected.map { |v| [v.layer, v.format] }.uniq
      expected = Ceradoc::Roundtrip::Vector::Capabilities::LAYERS.flat_map do |layer, formats|
        formats.keys.map { |format| [layer, format] }
      end
      expect(sealed).to include(*expected)
    end
  end

  describe 'byte equality (deterministic serializer)' do
    selected.each do |vector|
      vector.sealed.sort.each do |fmt, _bytes|
        it "#{vector.id} [#{fmt}]" do
          outcome = results[vector.id] ||= Ceradoc::Roundtrip::VectorHarness.call(vector)
          result = outcome.find { |r| r.property == :byte_equality && r.format == fmt }

          expect(result&.detail).to be_nil, result.to_s
        end
      end
    end
  end

  describe 'structural equality (generated loader)' do
    selected.each do |vector|
      vector.sealed.sort.each do |fmt, _bytes|
        id = gap_id.call(vector, fmt)

        it "#{vector.id} [#{fmt}]" do
          pending(loader_gaps.reason(id)) if loader_gaps.include?(id)

          outcome = results[vector.id] ||= Ceradoc::Roundtrip::VectorHarness.call(vector)
          result = outcome.find { |r| r.property == :structural_equality && r.format == fmt }

          expect(result&.detail).to be_nil, result.to_s
        end
      end
    end
  end

  describe 'producer gaps ratchet' do
    # Which (vector, serialization format) generations fail right now.
    # One aggregated example: the sweep duplicates the byte loop's
    # parses and is not worth one example per gap. A parse crash is the
    # round-trip harness's business, not a serialization gap.
    it 'lists exactly the serializations that cannot generate' do
      failing = {}
      Ceradoc::Roundtrip::VectorSealer.curated_cases.each do |kase|
        next unless in_wanted_format.call(kase.id)

        Ceradoc::Roundtrip::Vector::Capabilities.layers_for(kase.format).each do |layer|
          lane = Ceradoc::Roundtrip::Vector::Capabilities.ruby_lane(layer, kase.format)
          model = lane.parse.call(kase.text)
          Ceradoc::Roundtrip::Vector::Capabilities::SEALED_FORMATS.each do |fmt|
            lane.serializers.fetch(fmt).call(model)
          rescue StandardError => e
            failing["#{kase.id}@#{layer}:#{fmt}"] = "#{e.class}: #{e.message.lines.first&.chomp}"
          end
        end
      rescue StandardError
        nil
      end

      listed = producer_gaps.ids.select { |id| in_wanted_format.call(id) }
      drift = (listed - failing.keys) + (failing.keys - listed)
      expect(drift).to eq([]), <<~TEXT
        producer gap list out of date (re-run rake roundtrip:vectors:seal):
          listed but generating now: #{(listed - failing.keys).sort.join(', ')}
          failing now but unlisted: #{(failing.keys - listed).sort.join(', ')}
      TEXT
    end

    it 'uses vector-shaped ids' do
      layers = Ceradoc::Roundtrip::Vector::Capabilities::LAYERS.keys.join('|')
      formats = Ceradoc::Roundtrip::Vector::Capabilities::SEALED_FORMATS.join('|')

      expect(producer_gaps.ids).to all(match(/@(#{layers}):(#{formats})\z/))
    end
  end

  it 'loader gaps and producer gaps are disjoint (a generation that raises cannot also load)' do
    expect(loader_gaps.ids & producer_gaps.ids).to eq([])
  end
end
