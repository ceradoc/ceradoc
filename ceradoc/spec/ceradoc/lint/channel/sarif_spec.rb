# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Ceradoc::Lint::Channel::Sarif do
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

  describe '#emit' do
    it 'emits the SARIF 2.1.0 document shape with the ceradoc driver' do
      output = described_class.new.emit(
        [diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading')]
      )

      parsed = JSON.parse(output)
      expect(parsed['version']).to eq('2.1.0')
      expect(parsed).to have_key('$schema')
      run = parsed['runs'].first
      expect(run['tool']['driver']['name']).to eq('ceradoc')
      result = run['results'].first
      expect(result).to include('ruleId' => 'ADOC001', 'level' => 'warning')
      expect(result['message']['text']).to eq('skips a heading')
      location = result['locations'].first
      expect(location['physicalLocation']['artifactLocation']).to include('uri' => 'a.adoc')
      expect(location['physicalLocation']['region']).to include('startLine' => 4)
    end

    it 'maps severities: error/error, warning/warning, info and hint/note' do
      findings = [
        diagnostic('A1', 'a.adoc', severity: 'error'),
        diagnostic('A2', 'a.adoc', severity: 'warning'),
        diagnostic('A3', 'a.adoc', severity: 'info'),
        diagnostic('A4', 'a.adoc', severity: 'hint')
      ]

      parsed = JSON.parse(described_class.new.emit(findings))
      expect(parsed['runs'].first['results'].map { |r| r['level'] })
        .to eq(%w[error warning note note])
    end

    it 'omits the region when the finding has no line' do
      parsed = JSON.parse(described_class.new.emit([diagnostic('ADOC001', 'a.adoc')]))
      location = parsed['runs'].first['results'].first['locations'].first

      expect(location['physicalLocation']).not_to have_key('region')
    end

    it 'omits the location when the finding has no anchor' do
      finding = Ceradoc::Lint::Diagnostic.new(code: 'ADOC001', severity: 'warning',
                                              message: 'm')

      parsed = JSON.parse(described_class.new.emit([finding]))
      expect(parsed['runs'].first['results'].first).not_to have_key('locations')
    end

    it 'deduplicates rules from the finding codes' do
      findings = [
        diagnostic('ADOC001', 'a.adoc', line: 4),
        diagnostic('ADOC001', 'a.adoc', line: 9),
        diagnostic('MD024', 'b.md')
      ]

      parsed = JSON.parse(described_class.new.emit(findings))
      rules = parsed['runs'].first['tool']['driver']['rules']

      expect(rules.map { |rule| rule['id'] }).to eq(%w[ADOC001 MD024])
      expect(rules.map { |rule| rule['name'] }).to eq(%w[ADOC001 MD024])
    end

    it 'excludes suppressed findings from the log' do
      findings = [diagnostic('ADOC001', 'a.adoc'), diagnostic('ADOC003', 'a.adoc')]
      channel = described_class.new(policy_layers: [suppress_layer(matches: 'ADOC003')])

      parsed = Ceradoc::Lint::Channel::Sarif::SarifLog.from_json(channel.emit(findings))

      expect(parsed.runs.first.results.map(&:rule_id)).to eq(%w[ADOC001])
    end

    it 'renders an empty run as a ceradoc run with no results' do
      parsed = JSON.parse(described_class.new.emit([]))
      run = parsed['runs'].first

      expect(run['tool']['driver']['name']).to eq('ceradoc')
      expect(run['results']).to eq([])
    end

    it 'emits the same log for the same input' do
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
    it 'parses the emitted log back into the SarifLog model' do
      findings = [
        diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading'),
        diagnostic('MD024', 'b.md', line: 9, severity: 'info', message: 'dup')
      ]

      log = Ceradoc::Lint::Channel::Sarif::SarifLog
            .from_json(described_class.new.emit(findings))

      expect(log.version).to eq('2.1.0')
      run = log.runs.first
      expect(run.tool.driver.name).to eq('ceradoc')
      expect(run.tool.driver.rules.map(&:id)).to eq(%w[ADOC001 MD024])

      first, second = run.results
      expect(first.rule_id).to eq('ADOC001')
      expect(first.level).to eq('warning')
      expect(first.message.text).to eq('skips a heading')
      expect(first.locations.first.physical_location.artifact_location.uri)
        .to eq('a.adoc')
      expect(first.locations.first.physical_location.region.start_line).to eq(4)

      expect(second.rule_id).to eq('MD024')
      expect(second.level).to eq('note')
      expect(second.locations.first.physical_location.region.start_line).to eq(9)
    end

    it 'defaults the version and schema when they are absent from the document' do
      log = Ceradoc::Lint::Channel::Sarif::SarifLog.from_json('{"runs":[]}')

      expect(log.version).to eq('2.1.0')
      expect(log.schema).to eq('https://json.schemastore.org/sarif-2.1.0.json')
      expect(log.runs).to eq([])
    end
  end
end
