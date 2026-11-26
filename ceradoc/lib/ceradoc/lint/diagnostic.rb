# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    # The diagnostic currency: one emitted rule finding, shared by every
    # stage (parse/lift/compose/validate/present/lint) and every channel
    # (terminal/JSON/SARIF/LSP — channels are generated serializers over
    # this model).
    #
    # Identity is the namespaced rule CODE, never prose. Codes are either
    # format-prefixed (ADOC001, MD024 — the prefix is the namespace) or
    # flavor-qualified dotted codes (iso.house-style.3) from flavor
    # catalogs; the catalog overlays severity/policy per code pattern,
    # and ceradoc never needs to know flavor names.
    #
    # Messages ride as a catalog reference plus typed interpolation
    # params; +message+ is the rendered fallback text the terminal
    # channel shows while no catalog resolves the ref. A lutaml model:
    # serialization, loading and equality are generated from the
    # declarations — no hand-rolled to_h, ever.
    #
    # @example
    #   Diagnostic.new(code: 'ADOC001', anchor: 'doc.adoc', line: 4,
    #                  severity: 'warning', message: 'skips a heading')
    class Diagnostic < Lutaml::Model::Serializable
      SEVERITIES = %w[error warning info hint].freeze
      DEFAULT_SEVERITY = 'warning'
      DEFAULT_CHANNEL = 'lint'

      attribute :code, :string
      attribute :anchor, :string
      attribute :line, :integer
      attribute :severity, :string
      attribute :message_ref, :string
      attribute :message, :string
      attribute :params, 'Ceradoc::Lint::MessageParam', collection: true
      attribute :policy, :string
      attribute :channel, :string

      # @!attribute [r] namespace
      #   The rule-code namespace: the leading segment of a dotted
      #   flavor code, else the alphabetic prefix of a format code
      #   (ADOC001 -> "adoc"). Policy layers key overrides on this.
      def namespace
        return code.split('.').first.downcase if code&.include?('.')

        code&.sub(/\d+\z/, '')&.downcase
      end

      def to_s
        line_part = line ? ":#{line}" : ''
        "#{anchor}#{line_part} [#{code}] #{message}"
      end
    end
  end
end
