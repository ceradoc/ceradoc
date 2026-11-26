# frozen_string_literal: true

module Ceradoc
  module Lint
    # Base class for lint rules. Subclasses (in the format gems)
    # declare:
    #
    #   id     [String]  stable namespaced rule code, e.g. 'ADOC001'
    #   format [Symbol]  registered format the rule applies to
    #   check(document, path) [Array<Diagnostic>] inspect the
    #     format-specific model tree
    #
    # Rules encapsulate their own traversal of the format model —
    # the framework never switches on node types (OCP: a new rule is
    # a new file, nothing else changes).
    class Rule
      class << self
        attr_reader :id, :format

        private

        def rule_id(id)
          @id = id
        end

        def applies_to(format)
          @format = format
        end
      end

      def id
        self.class.id
      end

      # Emit one finding in the diagnostic currency (#377): severity is
      # validated here, at the emit site; message_ref defaults to the
      # rule code until a message catalog resolves refs.
      def build_diagnostic(path:, message:, line: nil, severity: Diagnostic::DEFAULT_SEVERITY)
        unless Diagnostic::SEVERITIES.include?(severity.to_s)
          raise ArgumentError,
                "unknown severity #{severity.inspect} for rule #{id}"
        end

        Diagnostic.new(code: id, anchor: path, line: line,
                       severity: severity.to_s, message_ref: id, message: message,
                       channel: Diagnostic::DEFAULT_CHANNEL)
      end
    end
  end
end
