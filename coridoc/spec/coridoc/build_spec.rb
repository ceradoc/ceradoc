# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Coridoc.build' do
  it 'yields a DocumentElement for in-place mutation' do
    doc = Coridoc.build do |d|
      d.title = 'My Document'
    end

    expect(doc).to be_a(Coridoc::CoreModel::DocumentElement)
    expect(doc.title).to eq('My Document')
  end

  it 'returns the document directly without a block' do
    doc = Coridoc.build

    expect(doc).to be_a(Coridoc::CoreModel::DocumentElement)
    expect(doc.children).to eq([])
  end

  it 'composes with Base.build helpers for nested construction' do
    list = Coridoc::CoreModel::ListBlock.build do |ul|
      ul.add_item do |li|
        li.add_text('first')
        li.add_link('/slug/', text: 'second')
      end
    end

    doc = Coridoc.build do |d|
      d.children << Coridoc::CoreModel::ParagraphBlock.new(content: 'intro')
      d.children << list
    end

    expect(doc.children.size).to eq(2)
    expect(doc.children[0]).to be_a(Coridoc::CoreModel::ParagraphBlock)
    expect(doc.children[1]).to be_a(Coridoc::CoreModel::ListBlock)
    expect(doc.children[1].items.size).to eq(1)
  end

  it 'is serializable end-to-end' do
    doc = Coridoc.build do |d|
      d.title = 'Built'
      d.children << Coridoc::CoreModel::ParagraphBlock.new(content: 'body')
    end

    html = Coridoc.serialize(doc, to: :asciidoc)
    expect(html).to include('Built')
    expect(html).to include('body')
  end
end
