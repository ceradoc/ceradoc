# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::CoreModel::CalloutText do
  describe '.ordered' do
    it 'sorts callouts by index ascending' do
      c1 = Coridoc::CoreModel::Callout.new(index: 1, content: 'one')
      c2 = Coridoc::CoreModel::Callout.new(index: 2, content: 'two')
      c3 = Coridoc::CoreModel::Callout.new(index: 3, content: 'three')

      expect(described_class.ordered([c3, c1, c2]).map(&:index)).to eq([1, 2, 3])
    end

    it 'places nil-indexed callouts at the end' do
      with_index = Coridoc::CoreModel::Callout.new(index: 1, content: 'one')
      without_index = Coridoc::CoreModel::Callout.new(content: 'orphan')

      result = described_class.ordered([without_index, with_index])
      expect(result.first).to be(with_index)
      expect(result.last).to be(without_index)
    end

    it 'returns an empty array for nil input' do
      expect(described_class.ordered(nil)).to eq([])
    end
  end

  describe '.strip_markers' do
    it 'removes callout markers for the given indices' do
      callouts = [
        Coridoc::CoreModel::Callout.new(index: 1, content: 'one'),
        Coridoc::CoreModel::Callout.new(index: 2, content: 'two')
      ]
      code = "line one <1>\nline two <2>"

      expect(described_class.strip_markers(code, callouts)).to eq("line one\nline two")
    end

    it 'preserves literal <N> when no callouts reference that index' do
      callouts = [Coridoc::CoreModel::Callout.new(index: 1, content: 'one')]
      code = 'x = 1 if y < 2'

      expect(described_class.strip_markers(code, callouts)).to eq('x = 1 if y < 2')
    end

    it 'returns code unchanged for empty callouts' do
      expect(described_class.strip_markers("a <1>\nb", [])).to eq("a <1>\nb")
    end

    it 'returns code unchanged when callouts have no usable index' do
      callouts = [Coridoc::CoreModel::Callout.new(content: 'no index')]
      expect(described_class.strip_markers('a <1>', callouts)).to eq('a <1>')
    end

    it 'tolerates whitespace inside the marker' do
      callouts = [Coridoc::CoreModel::Callout.new(index: 1, content: 'one')]
      expect(described_class.strip_markers('code < 1 >', callouts)).to eq('code')
    end

    it 'strips trailing whitespace left after marker removal' do
      callouts = [Coridoc::CoreModel::Callout.new(index: 1, content: 'one')]
      expect(described_class.strip_markers('code   <1>   ', callouts)).to eq('code')
    end
  end
end
