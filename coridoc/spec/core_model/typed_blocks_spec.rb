# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CoreModel typed block subclasses' do
  shared_examples 'a typed block' do |klass, expected_semantic|
    let(:block_class) { klass }
    let(:semantic_type) { expected_semantic }

    describe "#{klass.name}.semantic_type" do
      it "returns #{expected_semantic}" do
        expect(klass.semantic_type).to eq(expected_semantic)
      end
    end

    describe "#{klass.name}#resolve_semantic_type" do
      it "returns #{expected_semantic} from class-level override" do
        block = klass.new(content: 'test')
        expect(block.resolve_semantic_type).to eq(expected_semantic)
      end

      it "returns #{expected_semantic} even when block_semantic_type is nil" do
        block = klass.new
        block.block_semantic_type = nil
        expect(block.resolve_semantic_type).to eq(expected_semantic)
      end
    end

    describe "#{klass.name}.new" do
      it 'does not require block_semantic_type (class IS the type)' do
        block = klass.new
        expect(block.block_semantic_type).to be_nil
        expect(block.resolve_semantic_type).to eq(expected_semantic)
      end

      it 'inherits from Block' do
        expect(klass.ancestors).to include(Coridoc::CoreModel::Block)
      end
    end
  end

  types = {
    Coridoc::CoreModel::SourceBlock => :source_code,
    Coridoc::CoreModel::ExampleBlock => :example,
    Coridoc::CoreModel::QuoteBlock => :quote,
    Coridoc::CoreModel::SidebarBlock => :sidebar,
    Coridoc::CoreModel::LiteralBlock => :literal,
    Coridoc::CoreModel::PassBlock => :pass,
    Coridoc::CoreModel::ListingBlock => :listing,
    Coridoc::CoreModel::OpenBlock => :open,
    Coridoc::CoreModel::VerseBlock => :verse,
    Coridoc::CoreModel::ReviewerBlock => :reviewer
  }

  types.each do |klass, semantic|
    describe klass.name do
      it_behaves_like 'a typed block', klass, semantic
    end
  end

  describe 'SourceBlock' do
    it 'accepts language attribute' do
      block = Coridoc::CoreModel::SourceBlock.new(
        content: 'puts "hi"',
        language: 'ruby'
      )
      expect(block.language).to eq('ruby')
    end
  end

  describe 'QuoteBlock' do
    it 'accepts attribution attribute' do
      block = Coridoc::CoreModel::QuoteBlock.new(
        content: 'To be or not to be',
        attribution: 'Shakespeare'
      )
      expect(block.attribution).to eq('Shakespeare')
    end
  end

  describe 'VerseBlock' do
    it 'accepts attribution attribute' do
      block = Coridoc::CoreModel::VerseBlock.new(
        content: 'Roses are red',
        attribution: 'Anonymous'
      )
      expect(block.attribution).to eq('Anonymous')
    end
  end

  describe 'ReviewerBlock' do
    it 'inherits from AnnotationBlock' do
      expect(Coridoc::CoreModel::ReviewerBlock.superclass).to eq(Coridoc::CoreModel::AnnotationBlock)
    end
  end

  describe 'ParagraphBlock' do
    it 'resolves :paragraph from class hierarchy' do
      block = Coridoc::CoreModel::ParagraphBlock.new(content: 'text')
      expect(block.resolve_semantic_type).to eq(:paragraph)
    end
  end

  describe 'CommentBlock' do
    it 'resolves :comment from class hierarchy' do
      block = Coridoc::CoreModel::CommentBlock.new(content: 'a comment')
      expect(block.resolve_semantic_type).to eq(:comment)
    end
  end

  describe 'HorizontalRuleBlock' do
    it 'resolves :horizontal_rule from class hierarchy' do
      block = Coridoc::CoreModel::HorizontalRuleBlock.new
      expect(block.resolve_semantic_type).to eq(:horizontal_rule)
    end
  end

  describe 'Block.resolve_semantic_type dispatch' do
    it 'returns nil for generic Block' do
      block = Coridoc::CoreModel::Block.new
      expect(block.resolve_semantic_type).to be_nil
    end

    it 'resolves from block_semantic_type attribute when no class override' do
      block = Coridoc::CoreModel::Block.new(block_semantic_type: 'sidebar')
      expect(block.resolve_semantic_type).to eq(:sidebar)
    end

    it 'prefers class-level semantic_type over block_semantic_type attribute' do
      block = Coridoc::CoreModel::SourceBlock.new(block_semantic_type: 'listing')
      expect(block.resolve_semantic_type).to eq(:source_code)
    end
  end
end
