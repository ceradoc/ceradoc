# frozen_string_literal: true

module Ceradoc
  module CoreModel
    class AbstractBlock < Block
      def self.semantic_type
        :abstract
      end
    end
  end
end
