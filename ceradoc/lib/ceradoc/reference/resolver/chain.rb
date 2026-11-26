# frozen_string_literal: true

module Ceradoc
  module Reference
    module Resolver
      # Tries each child resolver in order. First Resolved/Ambiguous
      # wins; Missing and Deferred fall through to the next resolver.
      # When every resolver fell through, a Missing beats a Deferred —
      # "asked and absent" is more informative than "could not ask" —
      # and Deferred beats a fabricated miss. Use to combine a local
      # catalog with a remote one without composite catalog indirection.
      class Chain < Resolver::Base
        attr_reader :resolvers

        def initialize(*resolvers)
          super()
          @resolvers = resolvers.flatten
        end

        def resolve(edge)
          last_missing = nil
          first_deferred = nil
          @resolvers.each do |resolver|
            result = resolver.resolve(edge)
            unresolvable = result.is_a?(Ceradoc::Reference::Result::Missing) ||
                           result.is_a?(Ceradoc::Reference::Result::Deferred)
            return result unless unresolvable

            last_missing = result if result.is_a?(Ceradoc::Reference::Result::Missing)
            first_deferred ||= result if result.is_a?(Ceradoc::Reference::Result::Deferred)
          end
          last_missing || first_deferred ||
            Ceradoc::Reference::Result::Missing.build(
              edge: edge, address: edge.address
            )
        end
      end
    end
  end
end
