# frozen_string_literal: true

module Coridoc
  module Reference
    module Result
      # Catalog knew the address; exactly one Content was returned.
      class Resolved < Base
        attribute :target, Coridoc::CoreModel::Base

        def self.build(edge:, address:, target:)
          new(edge: edge, address: address, target: target)
        end

        private

        def result_data
          { target: target }
        end
      end
    end
  end
end
