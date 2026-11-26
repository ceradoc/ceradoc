# frozen_string_literal: true

module Ceradoc
  module Lint
    module Channel
      # SARIF 2.1.0 channel (#379): the visible findings as one SARIF
      # log — runs[].tool.driver carries the deduplicated rule codes,
      # results[] carry one entry per finding. Generated serialization
      # over the SARIF model family below, no bespoke shapes; the
      # document parses back into SarifLog (round-trip property,
      # spec-tested).
      class Sarif
        autoload :SarifLog, "#{__dir__}/sarif/sarif_log"
        autoload :Run, "#{__dir__}/sarif/run"
        autoload :Tool, "#{__dir__}/sarif/tool"
        autoload :Driver, "#{__dir__}/sarif/driver"
        autoload :Rule, "#{__dir__}/sarif/rule"
        autoload :Result, "#{__dir__}/sarif/result"
        autoload :Message, "#{__dir__}/sarif/message"
        autoload :Location, "#{__dir__}/sarif/location"
        autoload :PhysicalLocation, "#{__dir__}/sarif/physical_location"
        autoload :ArtifactLocation, "#{__dir__}/sarif/artifact_location"
        autoload :Region, "#{__dir__}/sarif/region"

        DRIVER_NAME = 'ceradoc'

        # severity -> SARIF level: error and warning keep their name,
        # info and hint collapse to note.
        LEVELS = {
          'error' => 'error',
          'warning' => 'warning',
          'info' => 'note',
          'hint' => 'note'
        }.freeze

        # @param policy_layers [Array<PolicyLayer>] precedence order,
        #   later layers win (see Lint::Policy.resolve)
        def initialize(policy_layers: [])
          @policy_layers = policy_layers
        end

        # @param diagnostics [Array<Diagnostic>]
        # @return [String] the generated SARIF 2.1.0 log document
        def emit(diagnostics)
          findings = Channel.prepare(diagnostics, policy_layers: @policy_layers)
          SarifLog.new(version: SarifLog::VERSION,
                       schema: SarifLog::SCHEMA_URI,
                       runs: [build_run(findings)]).to_json
        end

        private

        # One run: the ceradoc driver over the deduplicated rule
        # codes, one result per visible finding.
        def build_run(findings)
          Run.new(
            tool: Tool.new(
              driver: Driver.new(name: DRIVER_NAME, rules: build_rules(findings))
            ),
            results: findings.map { |finding| build_result(finding) }
          )
        end

        # rules[] deduplicated from codes: id = code, name = code.
        def build_rules(findings)
          findings.map(&:code).uniq.map { |code| Rule.new(id: code, name: code) }
        end

        def build_result(finding)
          Result.new(
            rule_id: finding.code,
            level: level_for(finding),
            message: Message.new(text: finding.message),
            locations: build_locations(finding)
          )
        end

        # An absent severity falls out of the document (SARIF defaults
        # results to warning); a severity outside the Diagnostic
        # vocabulary is a bug in the emitter, not a rendering choice.
        def level_for(finding)
          return unless finding.severity

          LEVELS.fetch(finding.severity) do
            raise ArgumentError,
                  "unknown severity #{finding.severity.inspect} " \
                  "for code #{finding.code}"
          end
        end

        # locations carry the anchor as the artifact uri; the region
        # rides only when the finding has a line. A finding without an
        # anchor has no location at all.
        def build_locations(finding)
          return [] unless finding.anchor

          physical = PhysicalLocation.new(
            artifact_location: ArtifactLocation.new(uri: finding.anchor),
            region: finding.line && Region.new(start_line: finding.line)
          )
          [Location.new(physical_location: physical)]
        end
      end
    end
  end
end
