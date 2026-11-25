# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/reference'

RSpec.describe Ceradoc::Reference::Materializer::Passthrough do
  let(:address) { Ceradoc::Reference::Address.parse('ELF-5005-1#sec-3') }
  let(:edge) do
    Ceradoc::Reference::Edge.build(
      kind: :navigation, address: address, label: 'Section 3'
    )
  end
  let(:result) do
    Ceradoc::Reference::Result::Missing.build(edge: edge, address: address)
  end
  let(:materializer) { described_class.new }

  it 'returns the original node unchanged' do
    node = Ceradoc::CoreModel::CrossReferenceElement.new(
      target: 'sec-3', id: 'xref-1',
      children: [Ceradoc::CoreModel::TextElement.new(content: 'Section 3')]
    )
    inline = materializer.materialize(
      edge: edge,
      result: result,
      node: node,
      presentation: nil,
      pages: []
    )
    expect(inline).to be(node)
  end

  it 'never degrades an image into text' do
    node = Ceradoc::CoreModel::Image.new(src: 'images/pic.png', alt: 'My Alt', id: 'img-1')
    image_edge = Ceradoc::Reference::Edge.build(
      kind: :image_ref,
      address: Ceradoc::Reference::Address.parse('images/pic.png', hint: :path),
      label: 'My Alt'
    )
    inline = materializer.materialize(
      edge: image_edge,
      result: result,
      node: node,
      presentation: nil,
      pages: []
    )
    expect(inline).to be(node)
  end
end
