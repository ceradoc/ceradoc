# frozen_string_literal: true

module Ceradoc
  module Lint
    # Emission channels (#378): generated serializers over the
    # Diagnostic model. A channel never invents an output shape —
    # Terminal delegates to Diagnostic#to_s, Json rides the generated
    # lutaml mappings — and every channel renders the SAME visible
    # set, computed once by the shared pipeline below.
    module Channel
      autoload :Terminal, "#{__dir__}/channel/terminal"
      autoload :Json, "#{__dir__}/channel/json"

      module_function

      # Policy slot value that removes a finding from every channel.
      SUPPRESS_POLICY = 'suppress'

      # The channel class for an output format name.
      #
      # @param name [String, Symbol] 'text' or 'json'
      # @return [Class] the channel class
      # @raise [ArgumentError] on an unknown channel name
      def for(name)
        case name.to_s
        when 'text' then Terminal
        when 'json' then Json
        else raise ArgumentError,
                   "unknown lint channel #{name.inspect} (known: text, json)"
        end
      end

      # The shared visibility pipeline: resolve each diagnostic
      # against the policy layers (later layers win, see
      # Lint::Policy.resolve), drop findings whose policy slot
      # resolves to suppress, dedup on (code, anchor) keeping the
      # first, and order stably by (anchor, code, line).
      #
      # @param diagnostics [Array<Diagnostic>]
      # @param policy_layers [Array<PolicyLayer>] precedence order
      # @return [Array<Diagnostic>] exactly what channels may render
      def prepare(diagnostics, policy_layers: [])
        visible = diagnostics.reject do |diagnostic|
          resolved = Policy.resolve(diagnostic, layers: policy_layers)
          resolved.policy == SUPPRESS_POLICY
        end

        visible.uniq { |diagnostic| [diagnostic.code, diagnostic.anchor] }
               .each_with_index
               .sort_by { |diagnostic, index| diagnostic_order(diagnostic, index) }
               .map(&:first)
      end

      def diagnostic_order(diagnostic, index)
        [diagnostic.anchor.to_s, diagnostic.code.to_s,
         diagnostic.line.to_i, index]
      end
    end
  end
end
