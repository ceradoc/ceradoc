# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::AsciiDoc::Transform::CalloutMerger do
  describe '.call' do
    it 'returns an empty array for no children' do
      expect(described_class.call([])).to eq([])
    end

    it 'passes through children when no source block is present' do
      para = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> standalone note')

      result = described_class.call([para])

      expect(result.size).to eq(1)
      expect(result.first).to eq(para)
    end

    it 'attaches a single callout paragraph to a preceding SourceBlock' do
      src = Ceradoc::CoreModel::SourceBlock.new(
        content: "get '/hi' do <1>",
        language: 'ruby'
      )
      para = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> Returns hello world')

      result = described_class.call([src, para])

      expect(result.size).to eq(1)
      expect(result.first).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(result.first.callouts.size).to eq(1)
      expect(result.first.callouts.first.index).to eq(1)
      expect(result.first.callouts.first.content).to eq('Returns hello world')
    end

    it 'attaches a single callout paragraph to a preceding ListingBlock' do
      src = Ceradoc::CoreModel::ListingBlock.new(content: 'line <1>')
      para = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> annotation')

      result = described_class.call([src, para])

      expect(result.size).to eq(1)
      expect(result.first).to be_a(Ceradoc::CoreModel::ListingBlock)
      expect(result.first.callouts.first.index).to eq(1)
      expect(result.first.callouts.first.content).to eq('annotation')
    end

    it 'splits a multi-callout paragraph into separate Callouts' do
      src = Ceradoc::CoreModel::SourceBlock.new(content: "a <1>\nb <2>")
      para = Ceradoc::CoreModel::ParagraphBlock.new(
        content: '<1> First <2> Second'
      )

      result = described_class.call([src, para])

      callouts = result.first.callouts
      expect(callouts.size).to eq(2)
      expect(callouts.map(&:index)).to eq([1, 2])
      expect(callouts.map(&:content)).to eq(%w[First Second])
    end

    it 'collects callouts across multiple consecutive paragraphs' do
      src = Ceradoc::CoreModel::SourceBlock.new(content: 'code <1>')
      first = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> First')
      second = Ceradoc::CoreModel::ParagraphBlock.new(content: '<2> Second')

      result = described_class.call([src, first, second])

      expect(result.size).to eq(1)
      callouts = result.first.callouts
      expect(callouts.map(&:index)).to eq([1, 2])
      expect(callouts.map(&:content)).to eq(%w[First Second])
    end

    it 'stops merging when a non-callout paragraph appears' do
      src = Ceradoc::CoreModel::SourceBlock.new(content: 'code <1>')
      callout = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> note')
      regular = Ceradoc::CoreModel::ParagraphBlock.new(content: 'Just text')

      result = described_class.call([src, callout, regular])

      expect(result.size).to eq(2)
      expect(result.first).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(result.first.callouts.size).to eq(1)
      expect(result.last).to eq(regular)
    end

    it 'preserves order of unrelated children' do
      para1 = Ceradoc::CoreModel::ParagraphBlock.new(content: 'Intro')
      src = Ceradoc::CoreModel::SourceBlock.new(content: 'code <1>')
      callout = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> note')
      para2 = Ceradoc::CoreModel::ParagraphBlock.new(content: 'Outro')

      result = described_class.call([para1, src, callout, para2])

      expect(result.map(&:class)).to eq([
                                          Ceradoc::CoreModel::ParagraphBlock,
                                          Ceradoc::CoreModel::SourceBlock,
                                          Ceradoc::CoreModel::ParagraphBlock
                                        ])
    end

    it 'does not attach a callout paragraph to a non-verbatim block' do
      quote = Ceradoc::CoreModel::QuoteBlock.new(content: 'quoted <1>')
      para = Ceradoc::CoreModel::ParagraphBlock.new(content: '<1> note')

      result = described_class.call([quote, para])

      expect(result.size).to eq(2)
      expect(result.first.callouts).to be_empty
    end
  end
end
