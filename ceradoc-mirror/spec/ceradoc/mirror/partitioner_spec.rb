# frozen_string_literal: true

require 'spec_helper'

# Partitioner is a single-pass state machine that buckets built Mirror
# nodes for the JS-shape doc structure. These specs lock in the bucketing
# rules — including the metadata (frontmatter) bucket — so accidental
# regressions are caught.
RSpec.describe Ceradoc::Mirror::Partitioner do
  def para(text = 'x')
    Ceradoc::Mirror::Node::Paragraph.new(
      content: [Ceradoc::Mirror::Node::Text.new(text: text)]
    )
  end

  def clause(title = 'C')
    Ceradoc::Mirror::Node::Section.new(
      type: 'clause',
      attrs: Ceradoc::Mirror::Node::Section::Attrs.new(title: title, level: 1)
    )
  end

  def frontmatter_with(entries)
    Ceradoc::Mirror::Node::Frontmatter.new(
      attrs: Ceradoc::Mirror::Node::Frontmatter::Attrs.new(entries: entries)
    )
  end

  describe '.partition' do
    it 'places frontmatter in the metadata bucket, NOT preface' do
      fm = frontmatter_with([
                              Ceradoc::Mirror::Node::FrontmatterEntry.new(
                                key: 'title',
                                value: Ceradoc::Mirror::Node::FrontmatterValue.new(
                                  value_type: 'string', string_value: 'Doc'
                                )
                              )
                            ])
      buckets = described_class.partition([fm, para, clause])

      expect(buckets[:metadata]).to eq([fm])
      expect(buckets[:preface]).to eq([para])
      expect(buckets[:sections]).to eq([clause])
    end

    it 'preserves document order when frontmatter is sandwiched' do
      # Documents always emit frontmatter first; the partitioner must not
      # reorder it relative to other metadata-bearing nodes.
      fm = frontmatter_with([])
      buckets = described_class.partition([fm, para, clause])

      expect(buckets[:metadata]).to eq([fm])
      expect(buckets[:preface]).to eq([para])
      expect(buckets[:sections]).to eq([clause])
    end

    it 'always returns the five-bucket shape' do
      buckets = described_class.partition([])
      expect(buckets.keys).to contain_exactly(:preface, :sections, :bibliography,
                                              :trailing, :metadata)
    end

    it 'routes footnotes to trailing regardless of frontmatter presence' do
      fn = Ceradoc::Mirror::Node::Footnotes.new
      buckets = described_class.partition([frontmatter_with([]), fn])
      expect(buckets[:trailing]).to eq([fn])
      expect(buckets[:metadata]).to eq([frontmatter_with([])])
    end
  end

  describe 'integration with CoreModelToMirror (partition_structural: true)' do
    it 'emits frontmatter before preface in the wrapped doc' do
      core = Ceradoc::CoreModel::DocumentElement.new(
        children: [
          Ceradoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'T' }),
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'intro'),
          Ceradoc::CoreModel::SectionElement.new(title: 'S', level: 1)
        ]
      )
      mirror = Ceradoc::Mirror.transform(core, partition_structural: true)
      types = mirror.content.map(&:type)
      expect(types).to eq(%w[frontmatter preface sections])
    end

    it 'does not include frontmatter inside the preface bucket' do
      core = Ceradoc::CoreModel::DocumentElement.new(
        children: [
          Ceradoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'T' }),
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'intro')
        ]
      )
      mirror = Ceradoc::Mirror.transform(core, partition_structural: true)
      preface = mirror.content.find { |n| n.type == 'preface' }
      expect(preface.content.map(&:type)).to eq(%w[paragraph])
    end
  end
end
