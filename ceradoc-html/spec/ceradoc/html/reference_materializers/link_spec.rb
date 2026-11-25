# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::Html::ReferenceMaterializers::Link do
  let(:materializer) { described_class.new }

  it 'renders a LinkElement with the URL as target and label as text' do
    edge = Ceradoc::Reference::Edge.build(
      kind: :link,
      address: Ceradoc::Reference::Address.parse('https://example.com'),
      label: 'Example'
    )
    inline = materializer.materialize(edge: edge, result: nil, node: nil, presentation: nil, pages: [])
    expect(inline).to be_a(Ceradoc::CoreModel::LinkElement)
    expect(inline.target).to eq('https://example.com')
    expect(inline.content).to eq('Example')
  end

  it 'falls back to the address when no label is given' do
    edge = Ceradoc::Reference::Edge.build(
      kind: :link,
      address: Ceradoc::Reference::Address.parse('https://example.com')
    )
    inline = materializer.materialize(edge: edge, result: nil, node: nil, presentation: nil, pages: [])
    expect(inline.content).to eq('https://example.com')
  end
end
