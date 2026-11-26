# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    # Severity/policy as DATA: a layer is an ordered set of overrides,
    # and resolution walks layers in precedence order (engine defaults
    # first, then flavor < taste < document < invocation — later layers
    # win). Patterns match a code exactly, or a whole namespace via a
    # trailing ".*" ("iso.*"). Declared, never coded per flavor.
    class PolicyEntry < Lutaml::Model::Serializable
      attribute :matches, :string
      attribute :severity, :string
      attribute :policy, :string
    end

    class PolicyLayer < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :entries, 'Ceradoc::Lint::PolicyEntry', collection: true
    end

    module Policy
      module_function

      # Resolve the effective severity/policy for a diagnostic across
      # ordered layers. Returns the original diagnostic when nothing
      # matches (never mutates the input).
      #
      # @param diagnostic [Diagnostic]
      # @param layers [Array<PolicyLayer>] precedence order, last wins
      # @return [Diagnostic]
      def resolve(diagnostic, layers: [])
        entry = layers.filter_map do |layer|
          Array(layer.entries).reverse.find { |e| matches?(diagnostic, e) }
        end.last
        return diagnostic unless entry

        resolved = diagnostic.dup
        resolved.severity = entry.severity if entry.severity
        resolved.policy = entry.policy if entry.policy
        resolved
      end

      def matches?(diagnostic, entry)
        pattern = entry.matches.to_s
        return diagnostic.code == pattern unless pattern.end_with?('.*')

        ns = pattern.delete_suffix('.*')
        diagnostic.code.to_s.start_with?("#{ns}.") ||
          diagnostic.namespace == ns
      end
    end
  end
end
