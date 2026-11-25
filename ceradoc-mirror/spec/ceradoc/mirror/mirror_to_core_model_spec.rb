# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'

RSpec.describe Ceradoc::Mirror::MirrorToCoreModel do
  let(:reverse) { described_class.new }

  describe 'round-trip: CoreModel → Mirror → CoreModel' do
    it 'round-trips a simple document with title and paragraphs' do
      original = Ceradoc::CoreModel::DocumentElement.new(
        title: 'Round Trip',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(
            content: 'Hello world'
          )
        ]
      )

      mirror = Ceradoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      expect(restored).to be_a(Ceradoc::CoreModel::DocumentElement)
      expect(restored.title).to eq('Round Trip')
      expect(restored.children).not_to be_empty
    end

    it 'round-trips sections with levels' do
      original = Ceradoc::CoreModel::DocumentElement.new(
        title: 'Doc',
        children: [
          Ceradoc::CoreModel::SectionElement.new(
            title: 'Section One',
            level: 1,
            id: 'section-one',
            children: [
              Ceradoc::CoreModel::ParagraphBlock.new(content: 'Content')
            ]
          )
        ]
      )

      mirror = Ceradoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      section = restored.children.first
      expect(section).to be_a(Ceradoc::CoreModel::SectionElement)
      expect(section.title).to eq('Section One')
      expect(section.level).to eq(1)
      expect(section.id).to eq('section-one')
    end

    it 'round-trips code blocks with language' do
      original = Ceradoc::CoreModel::SourceBlock.new(
        content: "puts 'hi'",
        language: 'ruby'
      )

      mirror = Ceradoc::Mirror.transform(
        Ceradoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      code = restored.children.first

      expect(code).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(code.language).to eq('ruby')
    end

    it 'round-trips unordered lists' do
      original = Ceradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [
          Ceradoc::CoreModel::ListItem.new(content: 'First'),
          Ceradoc::CoreModel::ListItem.new(content: 'Second')
        ]
      )

      mirror = Ceradoc::Mirror.transform(
        Ceradoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      list = restored.children.first

      expect(list).to be_a(Ceradoc::CoreModel::ListBlock)
      expect(list.marker_type).to eq('unordered')
      expect(list.items.length).to eq(2)
    end

    it 'round-trips images' do
      original = Ceradoc::CoreModel::Image.new(
        src: 'photo.png',
        alt: 'Photo',
        caption: 'Figure 1'
      )

      mirror = Ceradoc::Mirror.transform(
        Ceradoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      image = restored.children.first

      expect(image).to be_a(Ceradoc::CoreModel::Image)
      expect(image.src).to eq('photo.png')
      expect(image.alt).to eq('Photo')
      expect(image.caption).to eq('Figure 1')
    end

    it 'round-trips bold text marks' do
      bold = Ceradoc::CoreModel::BoldElement.new(content: 'important')
      original = Ceradoc::CoreModel::ParagraphBlock.new(children: [bold])

      mirror = Ceradoc::Mirror.transform(
        Ceradoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      para = restored.children.first

      expect(para).to be_a(Ceradoc::CoreModel::Block)
    end

    it 'round-trips tables' do
      original = Ceradoc::CoreModel::Table.new(
        rows: [
          Ceradoc::CoreModel::TableRow.new(
            cells: [
              Ceradoc::CoreModel::TableCell.new(content: 'A'),
              Ceradoc::CoreModel::TableCell.new(content: 'B')
            ]
          )
        ]
      )

      mirror = Ceradoc::Mirror.transform(
        Ceradoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      table = restored.children.first

      expect(table).to be_a(Ceradoc::CoreModel::Table)
      expect(table.rows.length).to eq(1)
    end

    it 'round-trips frontmatter schema and data' do
      original = Ceradoc::CoreModel::DocumentElement.new(
        title: 'Doc',
        children: [
          Ceradoc::CoreModel::FrontmatterBlock.new(
            schema: 'https://example.com/s.json',
            entries: Ceradoc::CoreModel::FrontmatterBlock::Codec.entries_from_hash({ 'title' => 'Hello', 'count' => 42, 'tags' => %w[a b] })
          ),
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'body')
        ]
      )

      mirror = Ceradoc::Mirror.transform(original)
      rebuilt = reverse.call(mirror)

      fm = rebuilt.children.find { |c| c.is_a?(Ceradoc::CoreModel::FrontmatterBlock) }
      expect(fm).not_to be_nil
      expect(fm.schema).to eq('https://example.com/s.json')
      expect(Ceradoc::CoreModel::FrontmatterBlock::Codec.to_hash(fm)).to eq(
        'title' => 'Hello', 'count' => 42, 'tags' => %w[a b]
      )
    end
  end

  describe 'error handling' do
    it 'raises error for unknown node type' do
      node = Ceradoc::Mirror::Node.new(type: 'completely_unknown_type')
      expect { reverse.call(node) }.to raise_error(Ceradoc::Mirror::Error, /Unknown mirror node type/)
    end
  end
end
