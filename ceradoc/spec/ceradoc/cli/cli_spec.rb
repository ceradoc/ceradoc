# frozen_string_literal: true

require 'spec_helper'
require 'ceradoc/cli'
require 'fileutils'
require 'tmpdir'

RSpec.describe Ceradoc::CLI do
  let(:cli) { described_class.new }

  before do
    # Ensure format gems are loaded
    require 'ceradoc/html'
    require 'ceradoc/markdown'
  end

  describe '#formats' do
    it 'lists supported formats' do
      output = capture_stdout { cli.formats }

      expect(output).to include('Supported formats')
      expect(output).to include('html')
      expect(output).to include('markdown')
    end
  end

  describe '#version' do
    it 'displays the version' do
      output = capture_stdout { cli.version }

      expect(output).to include('Ceradoc')
      expect(output).to include(Ceradoc::VERSION)
    end
  end

  describe '#convert' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown to HTML conversion' do
      let(:input_file) { File.join(temp_dir, 'input.md') }
      let(:output_file) { File.join(temp_dir, 'output.html') }
      let(:markdown_content) { "# Title\n\nParagraph content" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'converts Markdown to HTML' do
        capture_stdout do
          cli.options = { to: 'html', output: output_file, verbose: false }
          cli.convert(input_file)
        end

        expect(File.exist?(output_file)).to be true
        html_content = File.read(output_file)
        expect(html_content).to include('<!DOCTYPE html>')
      end

      it 'outputs to stdout when no output file specified' do
        output = capture_stdout do
          cli.options = { to: 'html', verbose: false }
          cli.convert(input_file)
        end

        expect(output).to include('<!DOCTYPE html>')
      end
    end

    context 'with auto-detection' do
      let(:input_file) { File.join(temp_dir, 'document.md') }
      let(:markdown_content) { "# Title\n\nContent" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'auto-detects source format from extension' do
        output = capture_stdout do
          cli.options = { to: 'html', verbose: false }
          cli.convert(input_file)
        end

        expect(output).to include('<!DOCTYPE html>')
      end
    end

    context 'with invalid input' do
      it 'exits with error for non-existent file' do
        expect do
          cli.options = { to: 'html', verbose: false }
          cli.convert('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#validate' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with valid Markdown document' do
      let(:input_file) { File.join(temp_dir, 'valid.md') }
      let(:markdown_content) { "# Title\n\nValid paragraph content" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'runs the validate command on a parseable document' do
        expect do
          capture_stdout do
            cli.options = { format: nil, strict: false, verbose: false }
            cli.validate(input_file)
          end
        end.not_to raise_error
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, strict: false, verbose: false }
          cli.validate('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#query' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown document' do
      let(:input_file) { File.join(temp_dir, 'query.md') }
      let(:markdown_content) { "# Main Title\n\n## Section 1\n\nParagraph 1\n\n## Section 2\n\nParagraph 2" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'queries for sections' do
        output = capture_stdout do
          cli.options = { format: nil, output: 'text', verbose: false }
          cli.query(input_file, 'section')
        end

        expect(output).to include('Found')
        expect(output).to include('element')
      end

      it 'outputs in JSON format' do
        output = capture_stdout do
          cli.options = { format: nil, output: 'json', verbose: false }
          cli.query(input_file, 'paragraph')
        end

        expect(output).not_to be_empty
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, output: 'text', verbose: false }
          cli.query('/nonexistent/file.md', 'section')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#info' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown document' do
      let(:input_file) { File.join(temp_dir, 'info.md') }
      let(:markdown_content) { "# Document Title\n\nFirst paragraph.\n\nSecond paragraph." }

      before do
        File.write(input_file, markdown_content)
      end

      it 'displays document information' do
        output = capture_stdout do
          cli.options = { format: nil, verbose: false }
          cli.info(input_file)
        end

        expect(output).to include('Document Information')
        expect(output).to include('Format: markdown')
        expect(output).to include('File size:')
        expect(output).to include('Line count:')
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, verbose: false }
          cli.info('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe 'format detection (delegated to Ceradoc)' do
    it 'maps common aliases to format names' do
      expect(Ceradoc.normalize_format('adoc')).to eq(:asciidoc)
      expect(Ceradoc.normalize_format('md')).to eq(:markdown)
      expect(Ceradoc.normalize_format('html')).to eq(:html)
      expect(Ceradoc.normalize_format('docx')).to eq(:docx)
    end

    it 'maps file extensions to formats' do
      expect(Ceradoc.detect_format('file.md')).to eq(:markdown)
      expect(Ceradoc.detect_format('file.html')).to eq(:html)
      expect(Ceradoc.detect_format('file.adoc')).to eq(:asciidoc)
      expect(Ceradoc.detect_format('file.docx')).to eq(:docx)
    end

    it 'identifies binary formats' do
      expect(Ceradoc.binary_format?(:docx)).to be true
      expect(Ceradoc.binary_format?(:html)).to be false
    end
  end

  describe '#convert' do
    context 'when converting to docx' do
      it 'rejects docx as target format' do
        expect do
          cli.options = { to: 'docx', verbose: false }
          cli.convert('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#lint' do
    let(:temp_dir) { Dir.mktmpdir('ceradoc_lint_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    def write_bad_adoc
      path = File.join(temp_dir, 'bad.adoc')
      File.write(path, "intro\n\n== S\n\n==== Skips\n")
      path
    end

    def write_policy_layer(code)
      path = File.join(temp_dir, 'suppress.yml')
      File.write(path, <<~YAML)
        name: invocation
        entries:
          - matches: '#{code}'
            policy: suppress
      YAML
      path
    end

    # Captures stdout and the exit status (nil when the command
    # returned normally) — SystemExit must not escape into RSpec.
    def capture_stdout_with_exit
      original_stdout = $stdout
      $stdout = StringIO.new
      status = nil
      yield
      [$stdout.string, status]
    rescue SystemExit => e
      [$stdout.string, e.status]
    ensure
      $stdout = original_stdout
    end

    it 'prints findings as text and exits nonzero' do
      output, status = capture_stdout_with_exit do
        cli.options = { format: 'text' }
        cli.lint(write_bad_adoc)
      end

      expect(status).to eq(1)
      expect(output).to include('[ADOC001]')
    end

    it 'exits zero on a clean document' do
      path = File.join(temp_dir, 'good.adoc')
      File.write(path, "= Title\n\n== S\n\ntext\n")

      output, status = capture_stdout_with_exit do
        cli.options = { format: 'text' }
        cli.lint(path)
      end

      expect(status).to be_nil
      expect(output).to include('No lint findings')
    end

    it 'prints only the JSON document on stdout and exits nonzero' do
      output, status = capture_stdout_with_exit do
        cli.options = { format: 'json' }
        cli.lint(write_bad_adoc)
      end

      expect(status).to eq(1)
      parsed = JSON.parse(output)
      expect(parsed['diagnostics'].map { |d| d['code'] }).to include('ADOC001')
    end

    it 'suppresses findings loaded from a policy layer file' do
      bad = write_bad_adoc
      policy = write_policy_layer('ADOC001')
      output, status = capture_stdout_with_exit do
        cli.options = { format: 'json', policy_layers: [policy] }
        cli.lint(bad)
      end

      expect(status).to eq(1)
      codes = JSON.parse(output)['diagnostics'].map { |d| d['code'] }
      expect(codes).not_to include('ADOC001')
      expect(codes).not_to be_empty
    end

    it 'exits zero when every finding is suppressed' do
      bad = write_bad_adoc
      policy = write_policy_layer('adoc.*')

      output, status = capture_stdout_with_exit do
        cli.options = { format: 'json', policy_layers: [policy] }
        cli.lint(bad)
      end

      expect(status).to be_nil
      expect(JSON.parse(output)['diagnostics']).to eq([])
    end
  end

  # Helper to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  rescue SystemExit
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
