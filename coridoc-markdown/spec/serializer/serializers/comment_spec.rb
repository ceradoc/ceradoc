# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::Markdown::Serializer::Serializers::Comment do
  let(:element) { Coridoc::Markdown::Comment.new(text: 'editorial note') }

  describe 'default (suppress_comments: true)' do
    it 'emits no output' do
      result = Coridoc::Markdown::Serializer.call(element)
      expect(result).to eq('')
    end

    it 'suppresses via the build API too' do
      result = Coridoc::Markdown::Serializer.build(:gfm).call(element)
      expect(result).to eq('')
    end
  end

  describe 'opt-in (suppress_comments: false)' do
    it 'emits an HTML comment with the text' do
      result = Coridoc::Markdown::Serializer.call(element, suppress_comments: false)
      expect(result).to eq('<!-- editorial note -->')
    end

    it 'emits <!----> for empty text' do
      empty = Coridoc::Markdown::Comment.new(text: '')
      result = Coridoc::Markdown::Serializer.call(empty, suppress_comments: false)
      expect(result).to eq('<!---->')
    end

    it 'strips whitespace around text' do
      padded = Coridoc::Markdown::Comment.new(text: '  padded  ')
      result = Coridoc::Markdown::Serializer.call(padded, suppress_comments: false)
      expect(result).to eq('<!-- padded -->')
    end

    it 'works via the block-builder API' do
      runner = Coridoc::Markdown::Serializer.build(:gfm) do |config|
        config.suppress_comments = false
      end
      expect(runner.call(element)).to eq('<!-- editorial note -->')
    end
  end

  describe 'through FromCoreModel (CommentBlock / CommentLine)' do
    it 'suppresses CommentBlock by default' do
      core = Coridoc::CoreModel::CommentBlock.new(content: 'hidden block text')
      md = Coridoc::Markdown.from_core_model(core)
      result = Coridoc::Markdown::Serializer.call(md)
      expect(result).to eq('')
    end

    it 'suppresses CommentLine by default' do
      core = Coridoc::CoreModel::CommentLine.new(text: 'silent line')
      md = Coridoc::Markdown.from_core_model(core)
      result = Coridoc::Markdown::Serializer.call(md)
      expect(result).to eq('')
    end

    it 'emits CommentBlock when suppress_comments is false' do
      core = Coridoc::CoreModel::CommentBlock.new(content: 'visible')
      md = Coridoc::Markdown.from_core_model(core)
      result = Coridoc::Markdown::Serializer.call(md, suppress_comments: false)
      expect(result).to eq('<!-- visible -->')
    end
  end
end
