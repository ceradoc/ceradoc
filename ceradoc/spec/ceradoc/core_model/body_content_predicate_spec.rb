# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc'

# Per-node predicates drive two open/closed dispatches:
#
#  * `body_content?` — false on ephemeral/metadata nodes
#    (CommentBlock, CommentLine, FrontmatterBlock). Used by
#    `StructuralElement#visible_children` and `#empty_body?`.
#
#  * `prose?` — false on ephemeral/metadata AND verbatim blocks
#    (SourceBlock, ListingBlock, LiteralBlock, PassBlock, StemBlock,
#    HorizontalRuleBlock). Used by LinkRewriter::Visitor and any
#    text-consuming plugin. Defaults to `body_content?` so ephemeral
#    classes don't need to override twice.
#
# Adding a new "skip me" type = overriding the predicate locally.
# No central walker, no VERBATIM_TYPES list to edit (OCP).
RSpec.describe 'CoreModel body_content / prose predicates' do
  describe 'body_content?' do
    it 'defaults to true on Base' do
      expect(Ceradoc::CoreModel::Base.new.body_content?).to be(true)
    end

    it 'is true on paragraph and standard block subclasses' do
      expect(Ceradoc::CoreModel::ParagraphBlock.new.body_content?).to be(true)
      expect(Ceradoc::CoreModel::Block.new.body_content?).to be(true)
    end

    it 'is false on CommentBlock' do
      expect(Ceradoc::CoreModel::CommentBlock.new.body_content?).to be(false)
    end

    it 'is false on CommentLine' do
      expect(Ceradoc::CoreModel::CommentLine.new.body_content?).to be(false)
    end

    it 'is false on FrontmatterBlock' do
      expect(Ceradoc::CoreModel::FrontmatterBlock.new.body_content?).to be(false)
    end
  end

  describe 'prose?' do
    it 'defaults to body_content? on Base' do
      base_instance = Ceradoc::CoreModel::Base.new
      expect(base_instance.prose?).to eq(base_instance.body_content?)
    end

    it 'is false on every body_content?=false class (inherited default)' do
      expect(Ceradoc::CoreModel::CommentBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::CommentLine.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::FrontmatterBlock.new.prose?).to be(false)
    end

    it 'is false on verbatim block types (override sites)' do
      expect(Ceradoc::CoreModel::SourceBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::ListingBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::LiteralBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::PassBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::StemBlock.new.prose?).to be(false)
      expect(Ceradoc::CoreModel::HorizontalRuleBlock.new.prose?).to be(false)
    end

    it 'is true on prose-bearing block types' do
      expect(Ceradoc::CoreModel::ParagraphBlock.new.prose?).to be(true)
      expect(Ceradoc::CoreModel::QuoteBlock.new.prose?).to be(true)
      expect(Ceradoc::CoreModel::ExampleBlock.new.prose?).to be(true)
      expect(Ceradoc::CoreModel::SidebarBlock.new.prose?).to be(true)
      expect(Ceradoc::CoreModel::OpenBlock.new.prose?).to be(true)
    end
  end

  describe 'whitespace_only?' do
    it 'defaults to false on Base' do
      expect(Ceradoc::CoreModel::Base.new.whitespace_only?).to be(false)
    end

    it 'is true on a TextContent with empty/whitespace text' do
      expect(Ceradoc::CoreModel::TextContent.new(text: '').whitespace_only?).to be(true)
      expect(Ceradoc::CoreModel::TextContent.new(text: '   ').whitespace_only?).to be(true)
    end

    it 'is false on a TextContent with non-whitespace text' do
      expect(Ceradoc::CoreModel::TextContent.new(text: 'hello').whitespace_only?).to be(false)
    end

    it 'is true on a ParagraphBlock with empty content' do
      paragraph = Ceradoc::CoreModel::ParagraphBlock.new(content: '')
      expect(paragraph.whitespace_only?).to be(true)
    end
  end

  describe 'StructuralElement#visible_children' do
    it 'selects body_content? children and rejects whitespace_only?' do
      para = Ceradoc::CoreModel::ParagraphBlock.new(content: 'real content')
      empty_para = Ceradoc::CoreModel::ParagraphBlock.new(content: '   ')
      comment = Ceradoc::CoreModel::CommentBlock.new(content: 'a comment')
      doc = Ceradoc::CoreModel::DocumentElement.new(children: [para, empty_para, comment])

      expect(doc.visible_children).to eq([para])
    end
  end

  describe 'StructuralElement#empty_body?' do
    it 'is true for a document with only comments' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [Ceradoc::CoreModel::CommentBlock.new(content: 'just a comment')]
      )
      expect(doc.empty_body?).to be(true)
    end

    it 'is true for a document with only frontmatter' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [Ceradoc::CoreModel::FrontmatterBlock.new]
      )
      expect(doc.empty_body?).to be(true)
    end

    it 'is true for an empty document' do
      expect(Ceradoc::CoreModel::DocumentElement.new.empty_body?).to be(true)
    end

    it 'is false when the document has a non-whitespace paragraph' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [Ceradoc::CoreModel::ParagraphBlock.new(content: 'body')]
      )
      expect(doc.empty_body?).to be(false)
    end

    it 'is true when paragraphs are all whitespace-only' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [Ceradoc::CoreModel::ParagraphBlock.new(content: '   ')]
      )
      expect(doc.empty_body?).to be(true)
    end

    it 'is false when the document has only source code (source IS body content)' do
      # Source blocks are body_content? = true (they're real content),
      # even though prose? = false (their text is literal). Empty-body
      # detection treats a source-only doc as non-empty.
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [Ceradoc::CoreModel::SourceBlock.new(content: 'puts "hi"')]
      )
      expect(doc.empty_body?).to be(false)
    end
  end
end
