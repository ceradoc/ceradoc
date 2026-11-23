# frozen_string_literal: true

require 'spec_helper'
require 'coridoc'
require 'coridoc/core_model'

RSpec.describe 'per-node body-content predicates' do
  describe 'Base defaults' do
    it 'returns true for body_content? on a generic node' do
      expect(Coridoc::CoreModel::Base.new).to be_body_content
    end

    it 'returns false for whitespace_only? on a generic node' do
      expect(Coridoc::CoreModel::Base.new).not_to be_whitespace_only
    end
  end

  describe 'body_content? overrides' do
    it 'returns false for CommentBlock' do
      expect(Coridoc::CoreModel::CommentBlock.new).not_to be_body_content
    end

    it 'returns false for CommentLine' do
      expect(Coridoc::CoreModel::CommentLine.new(text: '// note')).not_to be_body_content
    end

    it 'returns false for FrontmatterBlock' do
      fm = Coridoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'X' })
      expect(fm).not_to be_body_content
    end

    it 'returns true for ParagraphBlock (no override)' do
      expect(Coridoc::CoreModel::ParagraphBlock.new(content: 'hi')).to be_body_content
    end
  end

  describe 'whitespace_only? overrides' do
    it 'returns true for TextContent with empty text' do
      expect(Coridoc::CoreModel::TextContent.new(text: '')).to be_whitespace_only
    end

    it 'returns true for TextContent with only whitespace' do
      expect(Coridoc::CoreModel::TextContent.new(text: "  \n\t ")).to be_whitespace_only
    end

    it 'returns false for TextContent with visible characters' do
      expect(Coridoc::CoreModel::TextContent.new(text: 'word')).not_to be_whitespace_only
    end

    it 'returns true for ParagraphBlock with nil content and no children' do
      expect(Coridoc::CoreModel::ParagraphBlock.new).to be_whitespace_only
    end

    it 'returns true for ParagraphBlock whose children are all whitespace' do
      para = Coridoc::CoreModel::ParagraphBlock.new(
        children: [Coridoc::CoreModel::TextContent.new(text: '  ')]
      )
      expect(para).to be_whitespace_only
    end

    it 'returns false for ParagraphBlock with visible content' do
      expect(Coridoc::CoreModel::ParagraphBlock.new(content: 'Hello'))
        .not_to be_whitespace_only
    end

    it 'returns false for ParagraphBlock with a visible-text child' do
      para = Coridoc::CoreModel::ParagraphBlock.new(
        children: [Coridoc::CoreModel::TextContent.new(text: 'word')]
      )
      expect(para).not_to be_whitespace_only
    end
  end

  describe 'StructuralElement#visible_children' do
    it 'selects body_content nodes and rejects whitespace-only ones' do
      fm = Coridoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'X' })
      comment = Coridoc::CoreModel::CommentBlock.new(lines: ['c'])
      empty_para = Coridoc::CoreModel::ParagraphBlock.new(content: '   ')
      real_para = Coridoc::CoreModel::ParagraphBlock.new(content: 'real body')

      doc = Coridoc::CoreModel::DocumentElement.new(
        children: [fm, comment, empty_para, real_para]
      )

      expect(doc.visible_children).to eq([real_para])
    end

    it 'returns an empty array when children is nil' do
      expect(Coridoc::CoreModel::DocumentElement.new.visible_children).to eq([])
    end
  end

  describe 'StructuralElement#empty_body?' do
    it 'returns true for a document with no children' do
      expect(Coridoc::CoreModel::DocumentElement.new).to be_empty_body
    end

    it 'returns true for a comment-only document' do
      doc = Coridoc::CoreModel::DocumentElement.new(
        children: [Coridoc::CoreModel::CommentBlock.new(lines: ['hidden'])]
      )
      expect(doc).to be_empty_body
    end

    it 'returns true for a frontmatter-only document' do
      doc = Coridoc::CoreModel::DocumentElement.new(
        children: [Coridoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'X' })]
      )
      expect(doc).to be_empty_body
    end

    it 'returns true when every paragraph is whitespace-only' do
      doc = Coridoc::CoreModel::DocumentElement.new(
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: "  \n")]
      )
      expect(doc).to be_empty_body
    end

    it 'returns false when a real paragraph is present' do
      doc = Coridoc::CoreModel::DocumentElement.new(
        children: [
          Coridoc::CoreModel::FrontmatterBlock::Codec.from_hash({ 'title' => 'X' }),
          Coridoc::CoreModel::CommentBlock.new(lines: ['c']),
          Coridoc::CoreModel::ParagraphBlock.new(content: 'real body')
        ]
      )
      expect(doc).not_to be_empty_body
    end

    it 'recurses into nested StructuralElements (empty section does not count)' do
      empty_section = Coridoc::CoreModel::SectionElement.new(
        title: 'Empty',
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: '')]
      )
      doc = Coridoc::CoreModel::DocumentElement.new(children: [empty_section])
      expect(doc).to be_empty_body
    end

    it 'recurses into nested StructuralElements (section with content counts)' do
      real_section = Coridoc::CoreModel::SectionElement.new(
        title: 'Real',
        children: [Coridoc::CoreModel::ParagraphBlock.new(content: 'body')]
      )
      doc = Coridoc::CoreModel::DocumentElement.new(children: [real_section])
      expect(doc).not_to be_empty_body
    end
  end
end
