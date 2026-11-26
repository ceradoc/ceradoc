# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Reference
    module Validation
      # One reported reference problem — typed and positioned.
      #
      # +code+ is "<status>_<kind>" ("missing_navigation",
      # "ambiguous_citation", "deferred_include", ...); +severity+ is
      # one of SEVERITY_ERROR / SEVERITY_WARNING / SEVERITY_INFO;
      # +kind+ is the Edge kind; +address+ the target; +origin+ the
      # asking node's position in the document tree.
      class Diagnostic < Lutaml::Model::Serializable
        SEVERITY_ERROR = 'error'
        SEVERITY_WARNING = 'warning'
        SEVERITY_INFO = 'info'

        SEVERITIES = {
          Result::Missing => SEVERITY_ERROR,
          Result::Ambiguous => SEVERITY_WARNING,
          Result::Deferred => SEVERITY_INFO
        }.freeze

        STATUS_BY_CLASS = {
          Result::Missing => 'missing',
          Result::Ambiguous => 'ambiguous',
          Result::Deferred => 'deferred'
        }.freeze

        attribute :code, :string
        attribute :severity, :string
        attribute :kind, :string
        attribute :address, Ceradoc::Reference::Address
        attribute :origin, Ceradoc::Reference::Validation::Origin
        attribute :message, :string

        def error?
          severity == SEVERITY_ERROR
        end

        def warning?
          severity == SEVERITY_WARNING
        end

        def to_s
          "#{origin} [#{code}] #{message}"
        end

        class << self
          # Build the Diagnostic for a non-Resolved Result. Codes are
          # derived from the outcome and the Edge kind — never spelled
          # per call site (OCP: new kinds/statuses need no edit here).
          def for_result(edge:, result:, origin:)
            status = STATUS_BY_CLASS[result.class] ||
                     result.class.name.split('::').last.downcase
            new(
              code: "#{status}_#{edge.kind}",
              severity: SEVERITIES[result.class] || SEVERITY_ERROR,
              kind: edge.kind,
              address: result.address,
              origin: origin,
              message: message_for(status, result)
            )
          end

          def message_for(status, result)
            case status
            when 'missing'
              "No catalog knows the address #{result.address}"
            when 'ambiguous'
              "#{Array(result.candidates).size} candidates match #{result.address}"
            when 'deferred'
              "Unresolvable scheme — #{result.reason}"
            else
              "Unresolved reference to #{result.address}"
            end
          end
          private :message_for
        end
      end
    end
  end
end
