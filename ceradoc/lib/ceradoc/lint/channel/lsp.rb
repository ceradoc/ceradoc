# frozen_string_literal: true

require 'uri'

module Ceradoc
  module Lint
    module Channel
      # LSP channel (#379): the visible findings as a
      # publishDiagnostics document — one {uri, diagnostics} entry per
      # anchor, ranges and severities translated to the LSP
      # vocabulary (zero-based lines, 1-4 severity numbers). Generated
      # serialization over the LSP model family below, no bespoke
      # shapes; the document parses back into PublishDiagnostics
      # (round-trip property, spec-tested).
      class Lsp
        autoload :PublishDiagnostics, "#{__dir__}/lsp/publish_diagnostics"
        autoload :FileDiagnostics, "#{__dir__}/lsp/file_diagnostics"
        autoload :Diagnostic, "#{__dir__}/lsp/diagnostic"
        autoload :PositionRange, "#{__dir__}/lsp/position_range"
        autoload :Position, "#{__dir__}/lsp/position"

        SOURCE = 'ceradoc'

        # severity -> LSP DiagnosticSeverity: 1=Error 2=Warning
        # 3=Information 4=Hint.
        SEVERITIES = {
          'error' => 1,
          'warning' => 2,
          'info' => 3,
          'hint' => 4
        }.freeze

        # Anchors that already carry a URI scheme pass through; path
        # anchors become absolute file:// URIs.
        URI_PATTERN = /\A[a-z][a-z0-9+.-]*:/i

        # @param policy_layers [Array<PolicyLayer>] precedence order,
        #   later layers win (see Lint::Policy.resolve)
        def initialize(policy_layers: [])
          @policy_layers = policy_layers
        end

        # @param diagnostics [Array<Diagnostic>]
        # @return [String] the generated publishDiagnostics document:
        #   a JSON array of per-uri entries
        def emit(diagnostics)
          findings = Channel.prepare(diagnostics, policy_layers: @policy_layers)
          PublishDiagnostics.new(build_entries(findings)).to_json
        end

        private

        # One entry per anchor, in pipeline order; every finding of an
        # anchor groups under that anchor's uri.
        def build_entries(findings)
          findings.group_by(&:anchor).map do |anchor, grouped|
            FileDiagnostics.new(
              uri: uri_for(anchor),
              diagnostics: grouped.map { |finding| build_diagnostic(finding) }
            )
          end
        end

        def build_diagnostic(finding)
          Diagnostic.new(
            range: build_range(finding),
            severity: severity_for(finding),
            code: finding.code,
            source: SOURCE,
            message: finding.message
          )
        end

        # LSP ranges are zero-based and the span is the line itself;
        # findings without a line report at the top of the document.
        def build_range(finding)
          line = [finding.line.to_i, 1].max - 1
          position = Position.new(line: line, character: 0)
          PositionRange.new(start: position, end: position)
        end

        # An absent severity falls out of the document (LSP clients
        # treat it as Error); a severity outside the Diagnostic
        # vocabulary is a bug in the emitter, not a rendering choice.
        def severity_for(finding)
          return unless finding.severity

          SEVERITIES.fetch(finding.severity) do
            raise ArgumentError,
                  "unknown severity #{finding.severity.inspect} " \
                  "for code #{finding.code}"
          end
        end

        # A path anchor is made absolute and percent-escaped against
        # the working directory; a missing anchor yields no uri (the
        # lint pipeline always anchors findings).
        def uri_for(anchor)
          return if anchor.nil? || anchor.to_s.empty?
          return anchor if anchor.to_s.match?(URI_PATTERN)

          "file://#{URI::DEFAULT_PARSER.escape(File.expand_path(anchor))}"
        end
      end
    end
  end
end
