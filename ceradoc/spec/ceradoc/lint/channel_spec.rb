# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Ceradoc::Lint::Channel do
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

  describe '.prepare' do
    it 'orders stably by anchor, code, line' do
      prepared = described_class.prepare(
        [diagnostic('B002', 'z.adoc', line: 7),
         diagnostic('A002', 'a.adoc', line: 9),
         diagnostic('A001', 'a.adoc', line: 4)]
      )

      expect(prepared.map(&:code)).to eq(%w[A001 A002 B002])
    end

    it 'dedups on (code, anchor) keeping the first occurrence' do
      first = diagnostic('A001', 'a.adoc', line: 2, message: 'first')
      second = diagnostic('A001', 'a.adoc', line: 8, message: 'second')

      prepared = described_class.prepare([first, second])

      expect(prepared).to eq([first])
    end

    it 'drops findings whose policy slot resolves to suppress' do
      kept = diagnostic('ADOC001', 'a.adoc')
      dropped = diagnostic('ADOC003', 'a.adoc')
      layer = suppress_layer(matches: 'ADOC003')

      prepared = described_class.prepare([kept, dropped], policy_layers: [layer])

      expect(prepared).to eq([kept])
    end

    it 'keeps findings when no layer matches' do
      finding = diagnostic('ADOC001', 'a.adoc')

      expect(described_class.prepare([finding],
                                     policy_layers: [suppress_layer(matches: 'md.*')]))
        .to eq([finding])
    end

    it 'lets a later layer win on the same code' do
      finding = diagnostic('ADOC001', 'a.adoc')
      flavor = suppress_layer(matches: 'adoc.*')
      invocation = Ceradoc::Lint::PolicyLayer.new(
        name: 'invocation',
        entries: [Ceradoc::Lint::PolicyEntry.new(matches: 'ADOC001',
                                                 severity: 'error')]
      )

      expect(described_class.prepare([finding],
                                     policy_layers: [flavor, invocation]))
        .to eq([finding])
    end
  end

  describe '.for' do
    it 'resolves the text and json channels' do
      expect(described_class.for('text')).to eq(Ceradoc::Lint::Channel::Terminal)
      expect(described_class.for(:json)).to eq(Ceradoc::Lint::Channel::Json)
    end

    it 'rejects unknown channel names' do
      expect { described_class.for('sarif') }
        .to raise_error(ArgumentError, /sarif/)
    end
  end

  describe Ceradoc::Lint::Channel::Terminal do
    it 'delegates each line to Diagnostic#to_s' do
      findings = [diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading'),
                  diagnostic('MD024', 'b.md')]

      expect(described_class.new.emit(findings))
        .to eq("a.adoc:4 [ADOC001] skips a heading\nb.md [MD024] m")
    end

    it 'is suppressible through the policy slot' do
      findings = [diagnostic('ADOC001', 'a.adoc'), diagnostic('ADOC003', 'a.adoc')]
      channel = described_class.new(policy_layers: [suppress_layer(matches: 'ADOC003')])

      expect(channel.emit(findings)).to eq('a.adoc [ADOC001] m')
    end

    it 'dedups repeated (code, anchor) findings' do
      findings = [diagnostic('ADOC001', 'a.adoc', line: 2),
                  diagnostic('ADOC001', 'a.adoc', line: 9)]

      expect(described_class.new.emit(findings).lines.count).to eq(1)
    end

    it 'emits the same document for the same input' do
      findings = [diagnostic('B002', 'z.adoc'), diagnostic('A001', 'a.adoc', line: 3)]
      channel = described_class.new

      expect(channel.emit(findings)).to eq(channel.emit(findings.dup))
    end

    it 'emits nothing for an empty run' do
      expect(described_class.new.emit([])).to be_empty
    end
  end

  describe Ceradoc::Lint::Channel::Json do
    it 'emits the generated document shape' do
      output = described_class.new.emit([diagnostic('ADOC001', 'a.adoc', line: 4)])

      parsed = JSON.parse(output)
      expect(parsed.keys).to eq(['diagnostics'])
      expect(parsed['diagnostics'].first).to include(
        'code' => 'ADOC001', 'anchor' => 'a.adoc', 'line' => 4,
        'severity' => 'warning', 'message' => 'm'
      )
    end

    it 'round-trips back into Diagnostic models' do
      findings = [
        diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading'),
        diagnostic('MD024', 'b.md', line: 9, severity: 'error', message: 'dup')
      ]

      parsed = Ceradoc::Lint::Diagnostics.from_json(described_class.new.emit(findings))

      expect(parsed.diagnostics).to eq(
        Ceradoc::Lint::Channel.prepare(findings)
      )
    end

    it 'round-trips message params through the generated machinery' do
      finding = Ceradoc::Lint::Diagnostic.new(
        code: 'ADOC005', anchor: 'a.adoc', line: 9, severity: 'error',
        message_ref: 'ADOC005', message: 'nested too deep',
        params: [Ceradoc::Lint::MessageParam.new(name: 'depth', value: '7')]
      )

      parsed = Ceradoc::Lint::Diagnostics.from_json(described_class.new.emit([finding]))

      expect(parsed.diagnostics.first.params.first.name).to eq('depth')
      expect(parsed.diagnostics.first.params.first.value).to eq('7')
    end

    it 'excludes suppressed findings from the document' do
      findings = [diagnostic('ADOC001', 'a.adoc'), diagnostic('ADOC003', 'a.adoc')]
      channel = described_class.new(policy_layers: [suppress_layer(matches: 'ADOC003')])

      parsed = Ceradoc::Lint::Diagnostics.from_json(channel.emit(findings))

      expect(parsed.diagnostics.map(&:code)).to eq(%w[ADOC001])
    end

    it 'renders an empty run as an empty diagnostics collection' do
      output = described_class.new.emit([])
      parsed = Ceradoc::Lint::Diagnostics.from_json(output)

      expect(JSON.parse(output)).to eq('diagnostics' => [])
      expect(parsed.diagnostics).to eq([])
    end

    it 'indents the document when pretty is set' do
      findings = [diagnostic('ADOC001', 'a.adoc', line: 4)]

      expect(described_class.new(pretty: true).emit(findings))
        .to include("\n  \"diagnostics\"")
    end
  end

  describe Ceradoc::Lint::Diagnostics do
    it 'round-trips a collection through the generated serializers' do
      findings = [
        diagnostic('ADOC001', 'a.adoc', line: 4, message: 'skips a heading'),
        diagnostic('iso.house-style.3', 'a.adoc', line: 12, severity: 'hint')
      ]
      document = described_class.new(diagnostics: findings)

      expect(described_class.from_json(document.to_json).diagnostics).to eq(findings)
    end

    it 'defaults to an empty collection' do
      expect(described_class.new.diagnostics).to eq([])
      expect(described_class.from_json('{}').diagnostics).to eq([])
    end
  end
end
