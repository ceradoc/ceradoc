# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Ceradoc::Lint do
  def write_bad(dir)
    path = File.join(dir, 'bad.adoc')
    File.write(path, "intro\n\n== S\n\n==== Skips\n")
    path
  end

  def write_good(dir)
    path = File.join(dir, 'good.adoc')
    File.write(path, "= Title\n\n== S\n\ntext\n")
    path
  end

  it 'reports model-driven violations with rule ids' do
    Dir.mktmpdir do |dir|
      diagnostics = described_class.run(write_bad(dir))

      ids = diagnostics.map(&:code)
      expect(ids).to include('ADOC001', 'ADOC002', 'ADOC003')
      expect(diagnostics.first.anchor).to end_with('bad.adoc')
    end
  end

  it 'returns nothing for a clean document' do
    Dir.mktmpdir do |dir|
      expect(described_class.run(write_good(dir))).to be_empty
    end
  end

  it 'restricts rules with only:' do
    Dir.mktmpdir do |dir|
      diagnostics = described_class.run(write_bad(dir), only: %w[ADOC002])

      expect(diagnostics.map(&:code)).to eq(%w[ADOC002])
    end
  end

  it 'skips rules with except:' do
    Dir.mktmpdir do |dir|
      diagnostics = described_class.run(write_bad(dir), except: %w[ADOC003])

      expect(diagnostics.map(&:code)).not_to include('ADOC003')
    end
  end

  it 'lints a SourceGraph directly (twin integration)' do
    Dir.mktmpdir do |dir|
      graph = Ceradoc::SourceGraph.build(write_bad(dir))
      diagnostics = described_class.run(graph)

      expect(diagnostics.map(&:code)).to include('ADOC001')
    end
  end

  describe Ceradoc::Lint::Diagnostic do
    it 'formats as anchor:line [CODE] message' do
      d = described_class.new(code: 'ADOC001', anchor: 'a.adoc', line: 4,
                              message: 'skips', severity: 'warning')

      expect(d.to_s).to eq('a.adoc:4 [ADOC001] skips')
    end

    it 'omits the line part when unknown' do
      d = described_class.new(code: 'ADOC002', anchor: 'a.adoc', line: nil,
                              message: 'no title', severity: 'warning')

      expect(d.to_s).to eq('a.adoc [ADOC002] no title')
    end

    it 'derives the namespace from the rule code' do
      expect(described_class.new(code: 'ADOC001').namespace).to eq('adoc')
      expect(described_class.new(code: 'MD024').namespace).to eq('md')
      expect(described_class.new(code: 'iso.house-style.3').namespace).to eq('iso')
    end

    it 'round-trips through the generated serializers' do
      d = described_class.new(
        code: 'ADOC005', anchor: 'a.adoc', line: 9, severity: 'error',
        message_ref: 'ADOC005', message: 'nested too deep',
        params: [Ceradoc::Lint::MessageParam.new(name: 'depth', value: '7')],
        channel: 'lint'
      )

      loaded = described_class.from_json(d.to_json)

      expect(loaded).to eq(d)
      expect(loaded.params.first.name).to eq('depth')
    end
  end

  describe Ceradoc::Lint::Policy do
    let(:diagnostic) do
      Ceradoc::Lint::Diagnostic.new(code: 'ADOC003', anchor: 'a.adoc',
                                    severity: 'warning', message: 'x')
    end

    let(:flavor_layer) do
      Ceradoc::Lint::PolicyLayer.new(
        name: 'iso-flavor',
        entries: [Ceradoc::Lint::PolicyEntry.new(matches: 'adoc.*', severity: 'error')]
      )
    end

    let(:invocation_layer) do
      Ceradoc::Lint::PolicyLayer.new(
        name: 'invocation',
        entries: [Ceradoc::Lint::PolicyEntry.new(matches: 'ADOC003', severity: 'hint',
                                                 policy: 'suppress')]
      )
    end

    it 'returns the diagnostic unchanged when no layer matches' do
      expect(described_class.resolve(diagnostic, layers: [])).to equal(diagnostic)
    end

    it 'applies a namespace pattern from a flavor layer' do
      resolved = described_class.resolve(diagnostic, layers: [flavor_layer])

      expect(resolved.severity).to eq('error')
      expect(diagnostic.severity).to eq('warning')
    end

    it 'lets a later invocation layer override the flavor layer' do
      resolved = described_class.resolve(diagnostic, layers: [flavor_layer, invocation_layer])

      expect(resolved.severity).to eq('hint')
      expect(resolved.policy).to eq('suppress')
    end
  end

  describe Ceradoc::Lint::Registry do
    let(:rule_one) do
      Class.new(Ceradoc::Lint::Rule) do
        rule_id 'X001'
        applies_to :testing
      end
    end

    let(:rule_two) do
      Class.new(Ceradoc::Lint::Rule) do
        rule_id 'X002'
        applies_to :testing
      end
    end

    let(:anonymous) { Class.new(Ceradoc::Lint::Rule) }

    def registry
      reg = described_class.new
      reg.register(rule_one)
      reg.register(rule_two)
      reg
    end

    it 'selects rules by format' do
      expect(registry.for_format(:testing).map(&:id)).to eq(%w[X001 X002])
      expect(registry.for_format(:other)).to be_empty
    end

    it 'applies only/ and except/ filters' do
      expect(registry.for_format(:testing, only: %w[X002]).map(&:id)).to eq(%w[X002])
      expect(registry.for_format(:testing, except: %w[X002]).map(&:id)).to eq(%w[X001])
    end

    it 'rejects rules without id or format' do
      expect { registry.register(anonymous) }.to raise_error(ArgumentError, /id/)
    end
  end
end
