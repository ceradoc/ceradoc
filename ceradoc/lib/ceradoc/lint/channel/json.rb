# frozen_string_literal: true

module Ceradoc
  module Lint
    module Channel
      # JSON channel (#378): generated serialization of the visible
      # findings as one Diagnostics document — lutaml-model machinery
      # only, no hand-rolled shapes. The output parses back into
      # Diagnostic models (round-trip property, spec-tested).
      class Json
        # @param policy_layers [Array<PolicyLayer>] precedence order,
        #   later layers win (see Lint::Policy.resolve)
        # @param pretty [Boolean] indent the document for display
        def initialize(policy_layers: [], pretty: false)
          @policy_layers = policy_layers
          @pretty = pretty
        end

        # @param diagnostics [Array<Diagnostic>]
        # @return [String] the generated JSON document:
        #   {"diagnostics": [...]}
        def emit(diagnostics)
          document = Diagnostics.new(
            diagnostics: Channel.prepare(diagnostics,
                                         policy_layers: @policy_layers)
          )
          @pretty ? document.to_json(pretty: true) : document.to_json
        end
      end
    end
  end
end
