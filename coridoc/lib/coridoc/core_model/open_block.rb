# frozen_string_literal: true

module Coridoc
  module CoreModel
    # Open block — a generic container block with no special rendering
    class OpenBlock < Block
      def self.semantic_type
        :open
      end
    end
  end
end
