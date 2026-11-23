# frozen_string_literal: true

module Coridoc
  module Html
    class Postprocessor
      def self.process(coridoc)
        new(coridoc).process
      end

      def initialize(coridoc)
        @tree = coridoc
      end

      def process
        @tree
      end
    end
  end
end
