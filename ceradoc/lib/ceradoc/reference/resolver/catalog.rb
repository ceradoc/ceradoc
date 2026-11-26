# frozen_string_literal: true

module Ceradoc
  module Reference
    module Resolver
      # Asks one catalog. Applies the +ambiguous:+ policy in-line.
      # Does NOT apply the +missing:+ policy — that's the caller's
      # call (Resolution orchestrator) — but it does surface the
      # Missing Result so the caller can decide.
      #
      # +unrecognized:+ decides what happens when the catalog does not
      # carry the Address's scheme at all: +:missing+ (default) reports
      # a plain miss; +:defer+ surfaces Result::Deferred — nothing was
      # asked, so a scheme-aware resolver further down a Chain may still
      # resolve it.
      class Catalog < Resolver::Base
        attr_reader :catalog, :ambiguous_policy, :missing_policy,
                    :unrecognized_policy

        def initialize(catalog:, ambiguous: :disambiguate, missing: :warn,
                       unrecognized: :missing)
          super()
          @catalog = catalog
          @ambiguous_policy = ambiguous
          @missing_policy = missing
          @unrecognized_policy = unrecognized
        end

        def resolve(edge)
          address = edge.address
          unless catalog.recognizes_scheme?(address.scheme)
            return deferred_for(edge, address) if unrecognized_policy == :defer

            return missing_for(edge, address)
          end

          result = catalog.lookup(address)
          return missing_for(edge, address) if result.nil?

          return resolved_for(edge, address, result) unless result.is_a?(Array)

          resolve_ambiguous(edge, address, result)
        end

        private

        def resolved_for(edge, address, target)
          Ceradoc::Reference::Result::Resolved.build(
            edge: edge, address: address, target: target
          )
        end

        def resolve_ambiguous(edge, address, candidates)
          return ambiguous_error(address, candidates) if ambiguous_policy == :error
          return resolved_for(edge, address, candidates.first) if ambiguous_policy == :first

          # :disambiguate — warn, then deterministically take the first
          Ceradoc::Logger.warn(
            "Reference #{address} is ambiguous " \
            "(#{candidates.size} candidates); using first"
          )
          resolved_for(edge, address, candidates.first)
        end

        def ambiguous_error(address, candidates)
          raise Ceradoc::Reference::AmbiguousReferenceError,
                "Address #{address} matched #{candidates.size} candidates"
        end

        def missing_for(edge, address)
          case missing_policy
          when :error
            raise Ceradoc::Reference::MissingReferenceError,
                  "Address #{address} not found"
          else
            Ceradoc::Reference::Result::Missing.build(edge: edge, address: address)
          end
        end

        def deferred_for(edge, address)
          Ceradoc::Reference::Result::Deferred.build(
            edge: edge,
            address: address,
            reason: "no catalog handles scheme :#{address.scheme}"
          )
        end
      end
    end
  end
end
