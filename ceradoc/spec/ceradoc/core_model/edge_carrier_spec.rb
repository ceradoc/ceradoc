# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::CoreModel::EdgeCarrier do
  def deep_freeze(node)
    if node.is_a?(Ceradoc::CoreModel::HasChildren) && node.children.is_a?(Array)
      node.children.each { |child| deep_freeze(child) }
      node.children.freeze
    end
    node.freeze
  end

  describe 'declared edges on construction' do
    it 'declares the navigation edge of a cross-reference' do
      node = Ceradoc::CoreModel::CrossReferenceElement.new(
        target: 'sec-b', id: 'x1', content: 'Section B'
      )
      edge = node.edge

      expect(edge.kind).to eq('navigation')
      expect(edge.address.scheme).to eq('anchor')
      expect(edge.address.target).to eq('sec-b')
      expect(edge.source_id).to eq('x1')
      expect(edge.label).to eq('Section B')
    end

    it 'declares the link edge with an inferred scheme' do
      node = Ceradoc::CoreModel::LinkElement.new(
        target: 'https://example.com', id: 'l1', content: 'ext'
      )
      edge = node.edge

      expect(edge.kind).to eq('link')
      expect(edge.address.scheme).to eq('url')
      expect(edge.source_id).to eq('l1')
      expect(edge.label).to eq('ext')
    end

    it 'declares the include edge wrapping the typed IncludeOptions' do
      options = Ceradoc::CoreModel::IncludeOptions.from_hash(
        { 'tags' => '*', 'leveloffset' => '+2' }
      )
      node = Ceradoc::CoreModel::Include.new(target: 'a.adoc', options: options)
      edge = node.edge

      expect(edge.kind).to eq('include')
      expect(edge.address.scheme).to eq('path')
      expect(edge.options.include_options).to be(options)
    end

    it 'declares the image edge with alt text as label and option' do
      node = Ceradoc::CoreModel::Image.new(src: 'images/x.png', alt: 'X', id: 'i1')
      edge = node.edge

      expect(edge.kind).to eq('image_ref')
      expect(edge.address.scheme).to eq('path')
      expect(edge.address.target).to eq('images/x.png')
      expect(edge.label).to eq('X')
      expect(edge.options.alt_text).to eq('X')
    end

    it 'declares the footnote edge anchored at the target' do
      node = Ceradoc::CoreModel::FootnoteElement.new(target: 'note-1', id: 'fn-ref')
      edge = node.edge

      expect(edge.kind).to eq('footnote_ref')
      expect(edge.address.scheme).to eq('anchor')
      expect(edge.address.target).to eq('note-1')
      expect(edge.options.footnote_id).to eq('fn-ref')
    end

    it 'falls back to the node id when the footnote has no target' do
      node = Ceradoc::CoreModel::FootnoteElement.new(id: 'fn-7')

      expect(node.edge.address.target).to eq('fn-7')
    end
  end

  describe 'edgeless carriers' do
    it 'declares no edge when the reference field is absent' do
      expect(Ceradoc::CoreModel::Image.new(alt: 'no src').edge).to be_nil
      expect(Ceradoc::CoreModel::Image.new.edges).to eq([])
      expect(Ceradoc::CoreModel::Include.new.edge).to be_nil
    end

    it 'declares an edge once the reference field arrives' do
      image = Ceradoc::CoreModel::Image.new(alt: 'late')

      expect(image.edge).to be_nil
      image.src = 'x.png'
      expect(image.edge.address.target).to eq('x.png')
    end
  end

  describe 'writer sync' do
    it 're-derives the address when the target changes' do
      node = Ceradoc::CoreModel::LinkElement.new(target: 'https://a.example', id: 'l1')
      node.target = 'https://b.example'

      expect(node.edge.address.to_s).to eq('https://b.example')
    end

    it 're-derives the label when the content changes' do
      node = Ceradoc::CoreModel::CrossReferenceElement.new(target: 'sec-b', content: 'old')
      node.content = 'new'

      expect(node.edge.label).to eq('new')
    end

    it 're-derives when the image alt changes' do
      node = Ceradoc::CoreModel::Image.new(src: 'x.png', alt: 'old', id: 'i')
      node.alt = 'new'

      expect(node.edge.label).to eq('new')
      expect(node.edge.options.alt_text).to eq('new')
    end

    it 're-derives when the include options change' do
      node = Ceradoc::CoreModel::Include.new(target: 'a.adoc')
      options = Ceradoc::CoreModel::IncludeOptions.new
      node.options = options

      expect(node.edge.options.include_options).to be(options)
    end

    it 're-derives when the source id changes' do
      node = Ceradoc::CoreModel::CrossReferenceElement.new(target: 'sec-b', id: 'old')
      node.id = 'new'

      expect(node.edge.source_id).to eq('new')
    end
  end

  describe 'frozen nodes' do
    it 'derives edges without mutating a deep-frozen tree' do
      node = Ceradoc::CoreModel::CrossReferenceElement.new(
        target: 'sec-b', id: 'x1', content: 'Section B'
      )
      node.children = [Ceradoc::CoreModel::TextElement.new(content: 'Section B')]
      deep_freeze(node)

      expect(node.edges.size).to eq(1)
      expect(node.edge.kind).to eq('navigation')
      expect(node.frozen?).to be(true)
    end

    it 'derives stable values across repeated reads' do
      node = Ceradoc::CoreModel::LinkElement.new(target: 'https://a.example', id: 'l1')
      deep_freeze(node)

      first_read = node.edges
      second_read = node.edges

      expect(second_read).to eq(first_read)
    end
  end

  describe 'lutaml value round-trip' do
    it 'keeps the declared edge data through to_hash/from_hash' do
      node = Ceradoc::CoreModel::Image.new(src: 'x.png', alt: 'X', id: 'i1')
      restored = Ceradoc::CoreModel::Image.from_hash(node.to_hash)

      # The declared edges survive as data: kind, address, source and
      # label round-trip losslessly. (The options subclass identity is a
      # lutaml attribute-typing concern of Edge itself, out of scope.)
      expect(
        restored.edges.map do |edge|
          [edge.kind, edge.address.to_s, edge.source_id, edge.label]
        end
      ).to eq(
        node.edges.map do |edge|
          [edge.kind, edge.address.to_s, edge.source_id, edge.label]
        end
      )
    end
  end
end
