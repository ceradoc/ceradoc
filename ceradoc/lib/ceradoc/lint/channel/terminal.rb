# frozen_string_literal: true

module Ceradoc
  module Lint
    module Channel
      # Terminal channel (#378): one deterministic text line per
      # finding, delegating to Diagnostic#to_s
      # ("anchor:line [CODE] message"). No bespoke shape — the line
      # format IS the model's; suppression, dedup and order come from
      # the shared Channel pipeline.
      class Terminal
        # @param policy_layers [Array<PolicyLayer>] precedence order,
        #   later layers win (see Lint::Policy.resolve)
        def initialize(policy_layers: [])
          @policy_layers = policy_layers
        end

        # @param diagnostics [Array<Diagnostic>]
        # @return [String] one line per visible finding, joined by
        #   newlines; empty when nothing survives the pipeline
        def emit(diagnostics)
          Channel.prepare(diagnostics, policy_layers: @policy_layers)
                 .map(&:to_s)
                 .join("\n")
        end
      end
    end
  end
end
