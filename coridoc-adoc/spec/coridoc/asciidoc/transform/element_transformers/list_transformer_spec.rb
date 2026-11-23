# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::ElementTransformers::ListTransformer do
  describe '.transform_list' do
    it 'transforms an unordered list' do
      items = [
        Coridoc::AsciiDoc::Model::List::Item.new(
          marker: '*',
          content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Item 1')]
        ),
        Coridoc::AsciiDoc::Model::List::Item.new(
          marker: '*',
          content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Item 2')]
        )
      ]
      list = Coridoc::AsciiDoc::Model::List::Unordered.new(items: items)

      result = described_class.transform_list(list, 'unordered')

      expect(result).to be_a(Coridoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('unordered')
      expect(result.items.size).to eq(2)
      expect(result.items[0]).to be_a(Coridoc::CoreModel::ListItem)
      expect(result.items[0].content).to eq('Item 1')
      expect(result.items[1].content).to eq('Item 2')
    end

    it 'transforms an ordered list with nested list' do
      nested_items = [
        Coridoc::AsciiDoc::Model::List::Item.new(
          marker: '**',
          content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Nested')]
        )
      ]
      nested_list = Coridoc::AsciiDoc::Model::List::Unordered.new(items: nested_items)

      item = Coridoc::AsciiDoc::Model::List::Item.new(
        marker: '.',
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Outer')],
        nested: nested_list
      )
      list = Coridoc::AsciiDoc::Model::List::Ordered.new(items: [item])

      result = described_class.transform_list(list, 'ordered')

      expect(result).to be_a(Coridoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('ordered')
      expect(result.items.size).to eq(1)

      outer_item = result.items[0]
      expect(outer_item.content).to eq('Outer')
      expect(outer_item.nested_list).to be_a(Coridoc::CoreModel::ListBlock)
      expect(outer_item.nested_list.marker_type).to eq('unordered')
      expect(outer_item.nested_list.items[0].content).to eq('Nested')
    end

    it 'transforms a list item with inline markup' do
      item = Coridoc::AsciiDoc::Model::List::Item.new(
        marker: '*',
        content: [
          Coridoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          Coridoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
        ]
      )
      list = Coridoc::AsciiDoc::Model::List::Unordered.new(items: [item])

      result = described_class.transform_list(list, 'unordered')

      li = result.items.first
      expect(li.content).to match(/Hello\s+bold/)
      expect(li.children).to be_an(Array)
      expect(li.children.size).to eq(2)
      expect(li.children[1]).to be_a(Coridoc::CoreModel::BoldElement)
      expect(li.children[1].content).to eq('bold')
    end

    it 'transforms a definition list' do
      item = Coridoc::AsciiDoc::Model::List::DefinitionItem.new(
        id: 'def-1',
        terms: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Term 1')],
        contents: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Definition 1')]
      )
      list = Coridoc::AsciiDoc::Model::List::Definition.new(items: [item])

      result = described_class.transform_list(list, 'definition')

      expect(result).to be_a(Coridoc::CoreModel::DefinitionList)
      expect(result.items.size).to eq(1)
      expect(result.items[0]).to be_a(Coridoc::CoreModel::DefinitionItem)
      expect(result.items[0].id).to eq('def-1')
      expect(result.items[0].term).to eq('Term 1')
      expect(result.items[0].definitions.first).to include('Definition 1')
      expect(result.items[0].term_children).not_to be_empty
      expect(result.items[0].definition_children).not_to be_empty
    end

    it 'handles empty lists' do
      list = Coridoc::AsciiDoc::Model::List::Unordered.new(items: [])

      result = described_class.transform_list(list, 'unordered')

      expect(result).to be_a(Coridoc::CoreModel::ListBlock)
      expect(result.items).to be_empty
    end
  end
end
