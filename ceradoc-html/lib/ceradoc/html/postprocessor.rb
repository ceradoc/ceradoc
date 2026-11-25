# frozen_string_literal: true

module Ceradoc
  module Html
    class Postprocessor
      def self.process(ceradoc)
        new(ceradoc).process
      end

      def initialize(ceradoc)
        @tree = ceradoc
      end

      def process
        @tree
      end
    end
  end
end
