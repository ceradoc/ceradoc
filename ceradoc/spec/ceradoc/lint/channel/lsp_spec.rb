# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'uri'

RSpec.describe Ceradoc::Lint::Channel::Lsp do
  def diagnostic(code, anchor, line: nil, message: 'm', severity: 'warning')
    Ceradoc::Lint::Diagnostic.new(code: code, anchor: anchor, line: line,
                                  severity: severity, message: message)
  end

  def suppress_layer(matches:, policy: 'suppress')
    Ceradoc::Lint::PolicyLayer.new(
      name: 'spec',
      entries: [Ceradoc::Lint::PolicyEntry.new(matches: matches, policy: policy)]
    )
  end

  def file_uri(path)
    "file://#{URI::DEFAULT_PARSER.escape(File.expand_path(path))}"
  end

  describe '#emit' do
    it 'emits one publishDiagnostics entry per anchor' do
      output = described_class.new.emit(
        [diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading')]
      )

      parsed = JSON.parse(output)
      entry = parsed.first
      expect(entry['uri']).to eq(file_uri('a.adoc'))
      diagnostic_json = entry['diagnostics'].first
      expect(diagnostic_json).to include(
        'code' => 'ADOC001', 'source' => 'ceradoc',
        'severity' => 2, 'message' => 'skips a heading'
      )
      expect(diagnostic_json['range']).to eq(
        'start' => { 'line' => 3, 'character' => 0 },
        'end' => { 'line' => 3, 'character' => 0 }
      )
    end

    it 'groups the findings of one anchor into a single entry' do
      findings = [diagnostic('ADOC001', 'a.adoc', line: 4),
                  diagnostic('ADOC005', 'a.adoc', line: 8),
                  diagnostic('MD024', 'b.md')]

      parsed = JSON.parse(described_class.new.emit(findings))

      expect(parsed.map { |entry| entry['uri'] })
        .to eq([file_uri('a.adoc'), file_uri('b.md')])
      expect(parsed.first['diagnostics'].map { |d| d['code'] })
        .to eq(%w[ADOC001 ADOC005])
    end

    it 'makes path anchors absolute file uris and passes uri anchors through' do
      findings = [diagnostic('ADOC001', 'a.adoc'),
                  diagnostic('MD024', 'https://example.com/doc.md')]

      parsed = JSON.parse(described_class.new.emit(findings))

      expect(parsed.map { |entry| entry['uri'] })
        .to eq([file_uri('a.adoc'), 'https://example.com/doc.md'])
    end

    it 'escapes path anchors into valid uris' do
      anchor = 'doc with space.adoc'

      parsed = JSON.parse(described_class.new.emit([diagnostic('ADOC001', anchor)]))

      expect(parsed.first['uri']).to eq(file_uri(anchor))
      expect(parsed.first['uri']).not_to include(' ')
    end

    it 'maps severities: error/1, warning/2, info/3, hint/4' do
      findings = [
        diagnostic('A1', 'a.adoc', severity: 'error'),
        diagnostic('A2', 'a.adoc', severity: 'warning'),
        diagnostic('A3', 'a.adoc', severity: 'info'),
        diagnostic('A4', 'a.adoc', severity: 'hint')
      ]

      parsed = JSON.parse(described_class.new.emit(findings))
      expect(parsed.first['diagnostics'].map { |d| d['severity'] })
        .to eq([1, 2, 3, 4])
    end

    it 'reports findings without a line at the top of the document' do
      parsed = JSON.parse(described_class.new.emit([diagnostic('ADOC001', 'a.adoc')]))
      range = parsed.first['diagnostics'].first['range']

      expect(range['start']).to eq('line' => 0, 'character' => 0)
      expect(range['end']).to eq(range['start'])
    end

    it 'excludes suppressed findings from the document' do
      findings = [diagnostic('ADOC001', 'a.adoc'), diagnostic('ADOC003', 'a.adoc')]
      channel = described_class.new(policy_layers: [suppress_layer(matches: 'ADOC003')])

      parsed = Ceradoc::Lint::Channel::Lsp::PublishDiagnostics
               .from_json(channel.emit(findings))

      expect(parsed.items.flat_map { |entry| entry.diagnostics.map(&:code) })
        .to eq(%w[ADOC001])
    end

    it 'renders an empty run as an empty document' do
      output = described_class.new.emit([])

      expect(JSON.parse(output)).to eq([])
    end

    it 'emits the same document for the same input' do
      findings = [diagnostic('B002', 'z.adoc'), diagnostic('A001', 'a.adoc', line: 3)]
      channel = described_class.new

      expect(channel.emit(findings)).to eq(channel.emit(findings.dup))
    end

    it 'rejects a severity outside the Diagnostic vocabulary' do
      finding = diagnostic('ADOC001', 'a.adoc', severity: 'bogus')

      expect { described_class.new.emit([finding]) }
        .to raise_error(ArgumentError, /bogus/)
    end
  end

  describe 'round-trip' do
    it 'parses the emitted document back into the PublishDiagnostics model' do
      findings = [
        diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading'),
        diagnostic('MD024', 'b.md', line: 9, severity: 'hint', message: 'dup')
      ]

      doc = Ceradoc::Lint::Channel::Lsp::PublishDiagnostics
            .from_json(described_class.new.emit(findings))

      expect(doc.items.map(&:uri)).to eq([file_uri('a.adoc'), file_uri('b.md')])

      first, second = doc.items.flat_map(&:diagnostics)
      expect(first.code).to eq('ADOC001')
      expect(first.severity).to eq(2)
      expect(first.source).to eq('ceradoc')
      expect(first.message).to eq('skips a heading')
      expect(first.range.start.line).to eq(3)
      expect(first.range.start.character).to eq(0)
      expect(first.range.end.line).to eq(3)

      expect(second.code).to eq('MD024')
      expect(second.severity).to eq(4)
      expect(second.range.start.line).to eq(8)
    end

    it 'parses a bare empty array back into an empty document' do
      doc = Ceradoc::Lint::Channel::Lsp::PublishDiagnostics.from_json('[]')

      expect(doc.items).to eq([])
    end
  end
end
