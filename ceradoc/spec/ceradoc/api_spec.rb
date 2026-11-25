# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/html'
require 'ceradoc/markdown'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Ceradoc API' do
  describe '.detect_format' do
    it 'detects AsciiDoc from .adoc extension' do
      expect(Ceradoc.detect_format('document.adoc')).to eq(:asciidoc)
    end

    it 'detects AsciiDoc from .asciidoc extension' do
      expect(Ceradoc.detect_format('document.asciidoc')).to eq(:asciidoc)
    end

    it 'detects HTML from .html extension' do
      expect(Ceradoc.detect_format('page.html')).to eq(:html)
    end

    it 'detects HTML from .htm extension' do
      expect(Ceradoc.detect_format('page.htm')).to eq(:html)
    end

    it 'detects Markdown from .md extension' do
      expect(Ceradoc.detect_format('readme.md')).to eq(:markdown)
    end

    it 'detects Markdown from .markdown extension' do
      expect(Ceradoc.detect_format('doc.markdown')).to eq(:markdown)
    end

    it 'detects Markdown from .mdown extension' do
      expect(Ceradoc.detect_format('doc.mdown')).to eq(:markdown)
    end

    it 'detects DOCX from .docx extension' do
      expect(Ceradoc.detect_format('report.docx')).to eq(:docx)
    end

    it 'returns nil for unknown extensions' do
      expect(Ceradoc.detect_format('file.txt')).to be_nil
    end

    it 'is case-insensitive' do
      expect(Ceradoc.detect_format('file.MD')).to eq(:markdown)
      expect(Ceradoc.detect_format('file.HTML')).to eq(:html)
    end
  end

  describe '.binary_format?' do
    it 'returns true for :docx' do
      expect(Ceradoc.binary_format?(:docx)).to be true
    end

    it 'returns false for :asciidoc' do
      expect(Ceradoc.binary_format?(:asciidoc)).to be false
    end

    it 'returns false for :html' do
      expect(Ceradoc.binary_format?(:html)).to be false
    end

    it 'returns false for :markdown' do
      expect(Ceradoc.binary_format?(:markdown)).to be false
    end
  end

  describe '.parse_file' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_api_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'parses a Markdown file to CoreModel' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      doc = Ceradoc.parse_file(file)

      expect(doc).to be_a(Ceradoc::CoreModel::Base)
    end

    it 'auto-detects format from extension' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Hello\n\nWorld")

      doc = Ceradoc.parse_file(file)

      expect(doc).to be_a(Ceradoc::CoreModel::Base)
    end

    it 'uses explicit format when provided' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      doc = Ceradoc.parse_file(file, format: :markdown)

      expect(doc).to be_a(Ceradoc::CoreModel::Base)
    end

    it 'raises UnsupportedFormatError for unknown extensions without format' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Ceradoc.parse_file(file) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, 'content')

      expect { Ceradoc.parse_file(file, format: :nonexistent) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end

    it 'raises FileNotFoundError for missing file' do
      expect { Ceradoc.parse_file('/nonexistent/file.md') }.to raise_error(Ceradoc::FileNotFoundError)
    end
  end

  describe '.convert_file' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_api_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'converts a Markdown file to HTML' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nParagraph")

      html = Ceradoc.convert_file(file, to: :html)

      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Title')
    end

    it 'converts with explicit source format' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      html = Ceradoc.convert_file(file, from: :markdown, to: :html)

      expect(html).to include('<!DOCTYPE html>')
    end

    it 'raises UnsupportedFormatError for unknown source format' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Ceradoc.convert_file(file, to: :html) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end
  end

  describe '.convert' do
    it 'converts Markdown text to HTML' do
      html = Ceradoc.convert("# Hello\n\nWorld", from: :markdown, to: :html)
      expect(html).to include('<!DOCTYPE html>')
      expect(html).to include('Hello')
    end

    it 'raises UnsupportedFormatError for unregistered source' do
      expect { Ceradoc.convert('text', from: :nonexistent, to: :html) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end

    it 'raises UnsupportedFormatError for unregistered target' do
      expect do
        Ceradoc.convert('text', from: :markdown, to: :nonexistent)
      end.to raise_error(Ceradoc::UnsupportedFormatError)
    end
  end

  describe '.parse' do
    it 'parses Markdown text to CoreModel' do
      doc = Ceradoc.parse("# Title\n\nContent", format: :markdown)
      expect(doc).to be_a(Ceradoc::CoreModel::Base)
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      expect { Ceradoc.parse('text', format: :nonexistent) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end
  end

  describe '.serialize' do
    it 'serializes CoreModel to HTML' do
      doc = Ceradoc.parse("# Title\n\nParagraph", format: :markdown)
      html = Ceradoc.serialize(doc, to: :html)
      expect(html).to include('<!DOCTYPE html>')
    end

    it 'raises UnsupportedFormatError for unregistered format' do
      doc = Ceradoc::CoreModel::StructuralElement.new(element_type: 'document')
      expect { Ceradoc.serialize(doc, to: :nonexistent) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end
  end

  describe '.to_core' do
    it 'returns CoreModel as-is' do
      doc = Ceradoc::CoreModel::StructuralElement.new(element_type: 'document')
      expect(Ceradoc.to_core(doc)).to eq(doc)
    end

    it 'transforms Markdown model via handles_model? dispatch' do
      md_doc = Ceradoc::Markdown.parse("# Title\n\nContent")
      core = Ceradoc.to_core(md_doc)
      expect(core).to be_a(Ceradoc::CoreModel::Base)
    end

    it 'raises TransformationError for unknown model type' do
      expect { Ceradoc.to_core(Object.new) }.to raise_error(Ceradoc::TransformationError)
    end
  end

  describe '.detect_format (driven by registration options)' do
    it 'detects AsciiDoc from .adoc extension' do
      expect(Ceradoc.detect_format('document.adoc')).to eq(:asciidoc)
    end

    it 'detects HTML from .htm extension' do
      expect(Ceradoc.detect_format('page.htm')).to eq(:html)
    end

    it 'detects Markdown from .mdown extension' do
      expect(Ceradoc.detect_format('doc.mdown')).to eq(:markdown)
    end

    it 'returns nil for unknown extensions' do
      expect(Ceradoc.detect_format('file.txt')).to be_nil
    end
  end

  describe '.binary_format? (driven by registration options)' do
    it 'returns true for :docx' do
      expect(Ceradoc.binary_format?(:docx)).to be true
    end

    it 'returns false for :asciidoc' do
      expect(Ceradoc.binary_format?(:asciidoc)).to be false
    end

    it 'returns false for :html' do
      expect(Ceradoc.binary_format?(:html)).to be false
    end

    it 'returns false for :markdown' do
      expect(Ceradoc.binary_format?(:markdown)).to be false
    end
  end

  describe '.normalize_format (driven by registration aliases)' do
    it 'normalizes adoc to :asciidoc' do
      expect(Ceradoc.normalize_format('adoc')).to eq(:asciidoc)
    end

    it 'normalizes md to :markdown' do
      expect(Ceradoc.normalize_format('md')).to eq(:markdown)
    end

    it 'passes through unknown formats as symbols' do
      expect(Ceradoc.normalize_format('custom')).to eq(:custom)
    end

    it 'returns nil for nil' do
      expect(Ceradoc.normalize_format(nil)).to be_nil
    end

    it 'handles symbols' do
      expect(Ceradoc.normalize_format(:adoc)).to eq(:asciidoc)
    end

    it 'is case-insensitive' do
      expect(Ceradoc.normalize_format('ADOC')).to eq(:asciidoc)
    end
  end

  describe '.serialize_format?' do
    it 'returns true for :html' do
      expect(Ceradoc.serialize_format?(:html)).to be true
    end

    it 'returns true for :markdown' do
      expect(Ceradoc.serialize_format?(:markdown)).to be true
    end

    it 'returns true for :asciidoc' do
      expect(Ceradoc.serialize_format?(:asciidoc)).to be true
    end

    it 'returns true for :docx (supports serialization)' do
      expect(Ceradoc.serialize_format?(:docx)).to be true
    end

    it 'returns false for unregistered format' do
      expect(Ceradoc.serialize_format?(:nonexistent)).to be false
    end
  end

  describe '.parse_format?' do
    it 'returns true for :markdown' do
      expect(Ceradoc.parse_format?(:markdown)).to be true
    end

    it 'returns true for :html' do
      expect(Ceradoc.parse_format?(:html)).to be true
    end

    it 'returns true for :asciidoc' do
      expect(Ceradoc.parse_format?(:asciidoc)).to be true
    end

    it 'returns true for :docx' do
      expect(Ceradoc.parse_format?(:docx)).to be true
    end

    it 'returns false for unregistered format' do
      expect(Ceradoc.parse_format?(:nonexistent)).to be false
    end
  end

  describe '.resolve_output_format' do
    it 'detects format from output filename' do
      expect(Ceradoc.resolve_output_format('output.html')).to eq(:html)
    end

    it 'detects markdown from output filename' do
      expect(Ceradoc.resolve_output_format('out.md')).to eq(:markdown)
    end

    it 'defaults to :html when no output file given' do
      expect(Ceradoc.resolve_output_format(nil)).to eq(:html)
    end

    it 'defaults to :html for unknown extension' do
      expect(Ceradoc.resolve_output_format('output.xyz')).to eq(:html)
    end
  end

  describe '.file_info' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_file_info_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'returns file size and format for text files' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      info = Ceradoc.file_info(file)

      expect(info[:format]).to eq(:markdown)
      expect(info[:size]).to be > 0
      expect(info[:lines]).to eq(3)
    end

    it 'omits lines for binary formats' do
      file = File.join(temp_dir, 'doc.docx')
      File.write(file, 'binary content')

      info = Ceradoc.file_info(file)

      expect(info[:format]).to eq(:docx)
      expect(info).not_to have_key(:lines)
    end
  end

  describe '.validate_file' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_validate_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    it 'returns a Validation::Result for a parseable document' do
      file = File.join(temp_dir, 'doc.md')
      File.write(file, "# Title\n\nContent")

      result = Ceradoc.validate_file(file)

      expect(result).to be_a(Ceradoc::Validation::Result)
    end

    it 'raises UnsupportedFormatError for unknown extension' do
      file = File.join(temp_dir, 'doc.xyz')
      File.write(file, 'content')

      expect { Ceradoc.validate_file(file) }.to raise_error(Ceradoc::UnsupportedFormatError)
    end

    it 'accepts explicit format option' do
      file = File.join(temp_dir, 'doc.txt')
      File.write(file, "# Title\n\nParagraph")

      result = Ceradoc.validate_file(file, format: :markdown)

      expect(result).to be_a(Ceradoc::Validation::Result)
    end
  end

  describe '.document_stats' do
    it 'returns title for documents with title' do
      doc = Ceradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'My Doc',
        children: []
      )

      stats = Ceradoc.document_stats(doc)

      expect(stats[:title]).to eq('My Doc')
    end

    it 'returns child_count for documents with children' do
      doc = Ceradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'A'),
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'B')
        ]
      )

      stats = Ceradoc.document_stats(doc)

      expect(stats[:child_count]).to eq(2)
    end

    it 'returns empty hash for elements without children' do
      doc = Ceradoc::CoreModel::Image.new(src: 'test.png')

      stats = Ceradoc.document_stats(doc)

      expect(stats).to eq({})
    end

    it 'counts all element types dynamically' do
      doc = Ceradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'A'),
          Ceradoc::CoreModel::AnnotationBlock.new(annotation_type: 'note', content: 'B'),
          Ceradoc::CoreModel::ListBlock.new(marker_type: 'unordered')
        ]
      )

      stats = Ceradoc.document_stats(doc)
      counts = stats[:element_counts]

      expect(counts['paragraph']).to eq(1)
      expect(counts['annotation_block']).to eq(1)
      expect(counts['list_block']).to eq(1)
    end
  end

  describe '.describe_element' do
    it 'describes elements with title' do
      elem = Ceradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'My Doc'
      )

      expect(Ceradoc.describe_element(elem)).to eq('StructuralElement: My Doc')
    end

    it 'describes elements with content' do
      elem = Ceradoc::CoreModel::ParagraphBlock.new(
        content: 'Some text here'
      )

      expect(Ceradoc.describe_element(elem)).to eq('ParagraphBlock: Some text here')
    end

    it 'truncates long content' do
      long_text = 'A' * 60
      elem = Ceradoc::CoreModel::ParagraphBlock.new(
        content: long_text
      )

      expect(Ceradoc.describe_element(elem)).to eq("ParagraphBlock: #{'A' * 51}...")
    end

    it 'describes elements without title or content' do
      elem = Ceradoc::CoreModel::Image.new(src: 'test.png')

      expect(Ceradoc.describe_element(elem)).to eq('Image')
    end

    it 'returns to_s for non-CoreModel objects' do
      expect(Ceradoc.describe_element('plain string')).to eq('plain string')
    end
  end

  describe '.strip_unicode' do
    it 'strips unicode whitespace from both ends' do
      expect(Ceradoc.strip_unicode("\u00A0hello\u00A0")).to eq('hello')
    end

    it 'strips only from beginning when only: :begin' do
      expect(Ceradoc.strip_unicode("\u00A0hello\u00A0", only: :begin)).to eq("hello\u00A0")
    end

    it 'strips only from end when only: :end' do
      expect(Ceradoc.strip_unicode("\u00A0hello\u00A0", only: :end)).to eq("\u00A0hello")
    end

    it 'returns nil for nil input' do
      expect(Ceradoc.strip_unicode(nil)).to be_nil
    end

    it 'strips regular spaces too (\\p{Zs} includes ASCII space)' do
      expect(Ceradoc.strip_unicode(' hello ')).to eq('hello')
    end

    it 'preserves internal whitespace' do
      expect(Ceradoc.strip_unicode("\u00A0hello world\u00A0")).to eq('hello world')
    end
  end

  describe '.format_capabilities' do
    it 'returns a hash keyed by format name' do
      caps = Ceradoc.format_capabilities

      expect(caps).to be_a(Hash)
      expect(caps.keys).to include(:asciidoc, :html, :markdown, :docx)
    end

    it 'each value has parse and serialize booleans' do
      caps = Ceradoc.format_capabilities

      caps.each do |name, cap|
        expect(cap).to have_key(:parse), "Expected #{name} to have :parse key"
        expect(cap).to have_key(:serialize), "Expected #{name} to have :serialize key"
        expect([true, false]).to include(cap[:parse])
        expect([true, false]).to include(cap[:serialize])
      end
    end

    it 'all registered formats support parse' do
      caps = Ceradoc.format_capabilities

      caps.each do |name, cap|
        expect(cap[:parse]).to be(true), "Expected #{name} to support parsing"
      end
    end

    it 'all registered formats support serialize' do
      caps = Ceradoc.format_capabilities

      caps.each do |name, cap|
        expect(cap[:serialize]).to be(true), "Expected #{name} to support serialization"
      end
    end
  end
end
