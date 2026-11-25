# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mirror Include round-trip' do
  let(:options) do
    Ceradoc::CoreModel::IncludeOptions.from_hash(
      { 'tags' => '*', 'leveloffset' => '+2', 'indent' => '0' }
    )
  end
  let(:include_node) do
    Ceradoc::CoreModel::Include.new(
      target: 'shared/common.adoc',
      options: options,
      raw_options: 'tags=*,leveloffset=+2,indent=0'
    )
  end

  it 'carries the wildcard flag into the mirror node attrs' do
    mirror_node = Ceradoc::Mirror::Handlers::Include.call(include_node, context: nil)
    expect(mirror_node.attrs.tags_wildcard).to be(true)
    expect(mirror_node.attrs.tags_inverted).to be(false)
  end

  it 'rebuilds the typed wildcard options on the reverse trip' do
    mirror_node = Ceradoc::Mirror::Handlers::Include.call(include_node, context: nil)
    rebuilt = Ceradoc::Mirror::ReverseBuilder::Include.new(nil).build(mirror_node)
    expect(rebuilt.options.tags_wildcard).to be(true)
    expect(rebuilt.options.leveloffset.delta).to eq(2)
    expect(rebuilt.options.indent).to eq(0)
  end

  it 'preserves tags=* through a full mirror round-trip' do
    mirror_node = Ceradoc::Mirror::Handlers::Include.call(include_node, context: nil)
    json = mirror_node.to_json
    parsed = Ceradoc::Mirror::Node::Include.from_json(json)
    rebuilt = Ceradoc::Mirror::ReverseBuilder::Include.new(nil).build(parsed)
    expect(rebuilt.options.tags_wildcard).to be(true)
    expect(rebuilt.options.tags?).to be(true)
  end

  it 'preserves inverted tags=** through a full mirror round-trip' do
    inverted = Ceradoc::CoreModel::IncludeOptions.from_hash({ 'tags' => '**' })
    node = Ceradoc::CoreModel::Include.new(target: 'a.adoc', options: inverted)
    mirror_node = Ceradoc::Mirror::Handlers::Include.call(node, context: nil)
    rebuilt = Ceradoc::Mirror::ReverseBuilder::Include.new(nil).build(mirror_node)
    expect(rebuilt.options.tags_inverted).to be(true)
    expect(rebuilt.options.tags_wildcard).to be(false)
  end

  it 'preserves named tags through a full mirror round-trip' do
    named = Ceradoc::CoreModel::IncludeOptions.from_hash({ 'tags' => 'body;intro' })
    node = Ceradoc::CoreModel::Include.new(target: 'a.adoc', options: named)
    mirror_node = Ceradoc::Mirror::Handlers::Include.call(node, context: nil)
    rebuilt = Ceradoc::Mirror::ReverseBuilder::Include.new(nil).build(mirror_node)
    expect(rebuilt.options.tags).to eq(%w[body intro])
    expect(rebuilt.options.tags_wildcard).to be(false)
  end

  it 'serializes graph-mode documents to mirror_json without raising' do
    doc = Ceradoc::CoreModel::DocumentElement.new(
      id: 'd', title: 'D', children: [include_node]
    )
    expect { Ceradoc.serialize(doc, to: :mirror_json) }.not_to raise_error
  end
end
