# frozen_string_literal: true

require 'spec_helper'
require 'coridoc'
require 'coridoc/asciidoc'

RSpec.describe 'AsciiDoc frontmatter parser integration' do
  let(:frontmatter_yml) do
    <<~YAML
      author: Jane Doe
      date: 2026-06-14
      tags:
        - foo
        - bar
    YAML
  end

  let(:adoc_body) { "= Hello\n\nWorld.\n" }

  let(:adoc_text) { "---\n#{frontmatter_yml}\n---\n\n#{adoc_body}" }

  describe 'Coridoc::AsciiDoc.parse' do
    it 'strips frontmatter into Document#frontmatter' do
      doc = Coridoc::AsciiDoc.parse(adoc_text)
      expect(doc).to be_a(Coridoc::AsciiDoc::Model::Document)
      expect(doc.frontmatter).to include('author: Jane Doe')
      expect(doc.frontmatter).to include('date: 2026-06-14')
    end

    it 'parses the body normally when frontmatter present' do
      doc = Coridoc::AsciiDoc.parse(adoc_text)
      expect(doc.header.title.to_s).to eq('Hello')
    end

    it 'leaves frontmatter nil when document has no frontmatter' do
      doc = Coridoc::AsciiDoc.parse("= Just Title\n\nBody\n")
      expect(doc.frontmatter).to be_nil
    end

    it 'treats body without leading `---` as no frontmatter' do
      doc = Coridoc::AsciiDoc.parse("= Just Body\n")
      expect(doc.frontmatter).to be_nil
    end
  end

  describe 'Coridoc::AsciiDoc::Parser::FrontmatterParser' do
    it 'delegates to CoreModel::FrontmatterBlock::TextSplitter' do
      result = Coridoc::AsciiDoc::Parser::FrontmatterParser.call(adoc_text)
      expect(result.frontmatter?).to be(true)
      expect(result.frontmatter).to include('author: Jane Doe')
      expect(result.body).to start_with('= Hello')
    end

    it 'returns the same Result struct type as the shared splitter' do
      result = Coridoc::AsciiDoc::Parser::FrontmatterParser.call(adoc_text)
      expect(result).to be_a(Coridoc::CoreModel::FrontmatterBlock::TextSplitter::Result)
    end
  end
end
