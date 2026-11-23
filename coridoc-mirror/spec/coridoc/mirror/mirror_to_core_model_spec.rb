# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'

RSpec.describe Coridoc::Mirror::MirrorToCoreModel do
  let(:reverse) { described_class.new }

  describe 'round-trip: CoreModel → Mirror → CoreModel' do
    it 'round-trips a simple document with title and paragraphs' do
      original = Coridoc::CoreModel::DocumentElement.new(
        title: 'Round Trip',
        children: [
          Coridoc::CoreModel::ParagraphBlock.new(
            content: 'Hello world'
          )
        ]
      )

      mirror = Coridoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      expect(restored).to be_a(Coridoc::CoreModel::DocumentElement)
      expect(restored.title).to eq('Round Trip')
      expect(restored.children).not_to be_empty
    end

    it 'round-trips sections with levels' do
      original = Coridoc::CoreModel::DocumentElement.new(
        title: 'Doc',
        children: [
          Coridoc::CoreModel::SectionElement.new(
            title: 'Section One',
            level: 1,
            id: 'section-one',
            children: [
              Coridoc::CoreModel::ParagraphBlock.new(content: 'Content')
            ]
          )
        ]
      )

      mirror = Coridoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      section = restored.children.first
      expect(section).to be_a(Coridoc::CoreModel::SectionElement)
      expect(section.title).to eq('Section One')
      expect(section.level).to eq(1)
      expect(section.id).to eq('section-one')
    end

    it 'round-trips code blocks with language' do
      original = Coridoc::CoreModel::SourceBlock.new(
        content: "puts 'hi'",
        language: 'ruby'
      )

      mirror = Coridoc::Mirror.transform(
        Coridoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      code = restored.children.first

      expect(code).to be_a(Coridoc::CoreModel::SourceBlock)
      expect(code.language).to eq('ruby')
    end

    it 'round-trips unordered lists' do
      original = Coridoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [
          Coridoc::CoreModel::ListItem.new(content: 'First'),
          Coridoc::CoreModel::ListItem.new(content: 'Second')
        ]
      )

      mirror = Coridoc::Mirror.transform(
        Coridoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      list = restored.children.first

      expect(list).to be_a(Coridoc::CoreModel::ListBlock)
      expect(list.marker_type).to eq('unordered')
      expect(list.items.length).to eq(2)
    end

    it 'round-trips images' do
      original = Coridoc::CoreModel::Image.new(
        src: 'photo.png',
        alt: 'Photo',
        caption: 'Figure 1'
      )

      mirror = Coridoc::Mirror.transform(
        Coridoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      image = restored.children.first

      expect(image).to be_a(Coridoc::CoreModel::Image)
      expect(image.src).to eq('photo.png')
      expect(image.alt).to eq('Photo')
      expect(image.caption).to eq('Figure 1')
    end

    it 'round-trips bold text marks' do
      bold = Coridoc::CoreModel::BoldElement.new(content: 'important')
      original = Coridoc::CoreModel::ParagraphBlock.new(children: [bold])

      mirror = Coridoc::Mirror.transform(
        Coridoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      para = restored.children.first

      expect(para).to be_a(Coridoc::CoreModel::Block)
    end

    it 'round-trips tables' do
      original = Coridoc::CoreModel::Table.new(
        rows: [
          Coridoc::CoreModel::TableRow.new(
            cells: [
              Coridoc::CoreModel::TableCell.new(content: 'A'),
              Coridoc::CoreModel::TableCell.new(content: 'B')
            ]
          )
        ]
      )

      mirror = Coridoc::Mirror.transform(
        Coridoc::CoreModel::DocumentElement.new(children: [original])
      )
      restored = reverse.call(mirror)
      table = restored.children.first

      expect(table).to be_a(Coridoc::CoreModel::Table)
      expect(table.rows.length).to eq(1)
    end

    it 'round-trips frontmatter schema and data' do
      original = Coridoc::CoreModel::DocumentElement.new(
        title: 'Doc',
        children: [
          Coridoc::CoreModel::FrontmatterBlock.new(
            schema: 'https://example.com/s.json',
            entries: Coridoc::CoreModel::FrontmatterBlock::Codec.entries_from_hash({ 'title' => 'Hello', 'count' => 42, 'tags' => %w[a b] })
          ),
          Coridoc::CoreModel::ParagraphBlock.new(content: 'body')
        ]
      )

      mirror = Coridoc::Mirror.transform(original)
      rebuilt = reverse.call(mirror)

      fm = rebuilt.children.find { |c| c.is_a?(Coridoc::CoreModel::FrontmatterBlock) }
      expect(fm).not_to be_nil
      expect(fm.schema).to eq('https://example.com/s.json')
      expect(Coridoc::CoreModel::FrontmatterBlock::Codec.to_hash(fm)).to eq(
        'title' => 'Hello', 'count' => 42, 'tags' => %w[a b]
      )
    end
  end

  describe 'error handling' do
    it 'raises error for unknown node type' do
      node = Coridoc::Mirror::Node.new(type: 'completely_unknown_type')
      expect { reverse.call(node) }.to raise_error(Coridoc::Mirror::Error, /Unknown mirror node type/)
    end
  end
end
