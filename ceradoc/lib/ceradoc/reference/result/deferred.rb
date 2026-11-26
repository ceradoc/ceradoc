# frozen_string_literal: true

module Ceradoc
  module Reference
    module Result
      # No resolver in scope handles this Address's scheme — resolution
      # is deferred, not missing. Nothing was asked, so nothing was
      # "not found": a later catalog/resolver that gains the scheme can
      # still resolve it. Callers must not treat Deferred as an error.
      class Deferred < Base
        attribute :reason, :string

        def self.build(edge:, address:, reason:)
          new(edge: edge, address: address, reason: reason)
        end

        private

        def result_data
          { reason: reason }
        end
      end
    end
  end
end
