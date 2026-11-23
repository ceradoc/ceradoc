# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::Mirror::Mark do
  describe 'construction' do
    it 'creates a mark with type' do
      mark = described_class.new
      expect(mark.type).to eq('mark')
    end

    it 'uses PM_TYPE as default type' do
      mark = described_class.new
      expect(mark.type).to eq('mark')
    end
  end

  describe 'serialization' do
    it 'serializes to hash' do
      mark = Coridoc::Mirror::Mark::Bold.new
      expect(mark.to_hash).to eq({ 'type' => 'strong' })
    end

    it 'includes attrs when present' do
      mark = Coridoc::Mirror::Mark::Link.new(
        attrs: Coridoc::Mirror::Mark::Link::Attrs.new(href: 'https://example.com')
      )
      expect(mark.to_hash).to eq({
                                   'type' => 'link',
                                   'attrs' => { 'href' => 'https://example.com' }
                                 })
    end
  end

  describe 'deserialization' do
    it 'reconstructs from hash via subclass from_hash' do
      hash = { 'type' => 'strong' }
      mark = Coridoc::Mirror::Mark::Bold.from_hash(hash)
      expect(mark).to be_a(Coridoc::Mirror::Mark::Bold)
    end

    it 'deserializes link with href' do
      hash = {
        'type' => 'link',
        'attrs' => { 'href' => 'https://example.com' }
      }
      mark = Coridoc::Mirror::Mark::Link.from_hash(hash)
      expect(mark).to be_a(Coridoc::Mirror::Mark::Link)
      expect(mark.attrs.href).to eq('https://example.com')
    end
  end

  describe 'mark type subclasses' do
    it 'registers all subclasses in TYPE_TO_CLASS map' do
      marks = described_class::TYPE_TO_CLASS
      expect(marks['strong']).to eq(Coridoc::Mirror::Mark::Bold.name)
      expect(marks['emphasis']).to eq(Coridoc::Mirror::Mark::Italic.name)
      expect(marks['code']).to eq(Coridoc::Mirror::Mark::Monospace.name)
      expect(marks['link']).to eq(Coridoc::Mirror::Mark::Link.name)
      expect(marks['xref']).to eq(Coridoc::Mirror::Mark::CrossReference.name)
      expect(marks['highlight']).to eq(Coridoc::Mirror::Mark::Highlight.name)
      expect(marks['subscript']).to eq(Coridoc::Mirror::Mark::Subscript.name)
      expect(marks['superscript']).to eq(Coridoc::Mirror::Mark::Superscript.name)
    end

    it 'Link stores href in attrs' do
      mark = Coridoc::Mirror::Mark::Link.new(
        attrs: Coridoc::Mirror::Mark::Link::Attrs.new(href: 'https://example.com')
      )
      expect(mark.attrs.href).to eq('https://example.com')
      hash = mark.to_hash
      expect(hash['attrs']['href']).to eq('https://example.com')
    end

    it 'CrossReference stores target in attrs' do
      mark = Coridoc::Mirror::Mark::CrossReference.new(
        attrs: Coridoc::Mirror::Mark::CrossReference::Attrs.new(target: 'section-1')
      )
      expect(mark.attrs.target).to eq('section-1')
    end

    it 'Stem stores stem_type in attrs' do
      mark = Coridoc::Mirror::Mark::Stem.new(
        attrs: Coridoc::Mirror::Mark::Stem::Attrs.new(stem_type: 'latex')
      )
      expect(mark.attrs.stem_type).to eq('latex')
    end
  end
end
