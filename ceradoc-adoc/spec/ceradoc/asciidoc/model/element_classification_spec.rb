# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Element classification' do
  describe 'block_level?' do
    it 'Section is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Section.new.block_level?).to be(true)
    end

    it 'Paragraph is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Paragraph.new.block_level?).to be(true)
    end

    it 'Admonition is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Admonition.new.block_level?).to be(true)
    end

    it 'CommentBlock is block-level' do
      expect(Ceradoc::AsciiDoc::Model::CommentBlock.new.block_level?).to be(true)
    end

    it 'Table is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Table.new.block_level?).to be(true)
    end

    it 'Block::Core is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Block::Core.new.block_level?).to be(true)
    end

    it 'Block::Listing is block-level (inherits from Core)' do
      expect(Ceradoc::AsciiDoc::Model::Block::Listing.new.block_level?).to be(true)
    end

    it 'Block::Quote is block-level (inherits from Core)' do
      expect(Ceradoc::AsciiDoc::Model::Block::Quote.new.block_level?).to be(true)
    end

    it 'List::Ordered is block-level' do
      expect(Ceradoc::AsciiDoc::Model::List::Ordered.new.block_level?).to be(true)
    end

    it 'List::Unordered is block-level' do
      expect(Ceradoc::AsciiDoc::Model::List::Unordered.new.block_level?).to be(true)
    end

    it 'BlockImage is block-level' do
      expect(Ceradoc::AsciiDoc::Model::Image::BlockImage.new.block_level?).to be(true)
    end
  end

  describe 'inline?' do
    it 'Inline::Bold is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Bold.new.inline?).to be(true)
    end

    it 'Inline::Italic is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Italic.new.inline?).to be(true)
    end

    it 'Inline::Monospace is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Monospace.new.inline?).to be(true)
    end

    it 'Inline::Highlight is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Highlight.new.inline?).to be(true)
    end

    it 'Inline::Superscript is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Superscript.new.inline?).to be(true)
    end

    it 'Inline::Subscript is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Subscript.new.inline?).to be(true)
    end

    it 'Inline::Link is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Link.new.inline?).to be(true)
    end

    it 'Inline::Anchor is inline' do
      expect(Ceradoc::AsciiDoc::Model::Inline::Anchor.new.inline?).to be(true)
    end

    it 'TextElement is inline' do
      expect(Ceradoc::AsciiDoc::Model::TextElement.new.inline?).to be(true)
    end

    it 'InlineImage is inline' do
      expect(Ceradoc::AsciiDoc::Model::Image::InlineImage.new.inline?).to be(true)
    end

    it 'HardLineBreak returns :hardbreak' do
      expect(Ceradoc::AsciiDoc::Model::Inline::HardLineBreak.new.inline?).to eq(:hardbreak)
    end
  end

  describe 'non-block, non-inline elements' do
    it 'Title is neither block nor inline' do
      title = Ceradoc::AsciiDoc::Model::Title.new
      expect(title.block_level?).to be(false)
      expect(title.inline?).to be(false)
    end

    it 'List::Item is neither block nor inline' do
      item = Ceradoc::AsciiDoc::Model::List::Item.new
      expect(item.block_level?).to be(false)
      expect(item.inline?).to be(false)
    end

    it 'AttributeList is neither block nor inline' do
      attrs = Ceradoc::AsciiDoc::Model::AttributeList.new
      expect(attrs.block_level?).to be(false)
      expect(attrs.inline?).to be(false)
    end
  end

  describe 'SpacingStrategy integration' do
    let(:strategy) { Ceradoc::AsciiDoc::Serializer::SpacingStrategy }

    it 'uses polymorphic block_level? for spacing' do
      para = Ceradoc::AsciiDoc::Model::Paragraph.new
      section = Ceradoc::AsciiDoc::Model::Section.new

      expect(strategy.block_level?(para)).to be(true)
      expect(strategy.block_level?(section)).to be(true)
    end

    it 'uses polymorphic inline? for spacing' do
      bold = Ceradoc::AsciiDoc::Model::Inline::Bold.new
      text = Ceradoc::AsciiDoc::Model::TextElement.new

      expect(strategy.inline_level?(bold)).to be(true)
      expect(strategy.inline_level?(text)).to be(true)
    end

    it 'returns false for nil' do
      expect(strategy.block_level?(nil)).to be(false)
      expect(strategy.inline_level?(nil)).to be(false)
    end

    it 'treats strings as inline' do
      expect(strategy.inline_level?('text')).to be(true)
    end
  end
end
