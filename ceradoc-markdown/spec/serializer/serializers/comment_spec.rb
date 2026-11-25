# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::Markdown::Serializer::Serializers::Comment do
  let(:element) { Ceradoc::Markdown::Comment.new(text: 'editorial note') }

  describe 'default (suppress_comments: true)' do
    it 'emits no output' do
      result = Ceradoc::Markdown::Serializer.call(element)
      expect(result).to eq('')
    end

    it 'suppresses via the build API too' do
      result = Ceradoc::Markdown::Serializer.build(:gfm).call(element)
      expect(result).to eq('')
    end
  end

  describe 'opt-in (suppress_comments: false)' do
    it 'emits an HTML comment with the text' do
      result = Ceradoc::Markdown::Serializer.call(element, suppress_comments: false)
      expect(result).to eq('<!-- editorial note -->')
    end

    it 'emits <!----> for empty text' do
      empty = Ceradoc::Markdown::Comment.new(text: '')
      result = Ceradoc::Markdown::Serializer.call(empty, suppress_comments: false)
      expect(result).to eq('<!---->')
    end

    it 'strips whitespace around text' do
      padded = Ceradoc::Markdown::Comment.new(text: '  padded  ')
      result = Ceradoc::Markdown::Serializer.call(padded, suppress_comments: false)
      expect(result).to eq('<!-- padded -->')
    end

    it 'works via the block-builder API' do
      runner = Ceradoc::Markdown::Serializer.build(:gfm) do |config|
        config.suppress_comments = false
      end
      expect(runner.call(element)).to eq('<!-- editorial note -->')
    end
  end

  describe 'through FromCoreModel (CommentBlock / CommentLine)' do
    it 'suppresses CommentBlock by default' do
      core = Ceradoc::CoreModel::CommentBlock.new(content: 'hidden block text')
      md = Ceradoc::Markdown.from_core_model(core)
      result = Ceradoc::Markdown::Serializer.call(md)
      expect(result).to eq('')
    end

    it 'suppresses CommentLine by default' do
      core = Ceradoc::CoreModel::CommentLine.new(text: 'silent line')
      md = Ceradoc::Markdown.from_core_model(core)
      result = Ceradoc::Markdown::Serializer.call(md)
      expect(result).to eq('')
    end

    it 'emits CommentBlock when suppress_comments is false' do
      core = Ceradoc::CoreModel::CommentBlock.new(content: 'visible')
      md = Ceradoc::Markdown.from_core_model(core)
      result = Ceradoc::Markdown::Serializer.call(md, suppress_comments: false)
      expect(result).to eq('<!-- visible -->')
    end
  end
end
