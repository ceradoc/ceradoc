# frozen_string_literal: true

module Coridoc
  module CoreModel
    # Horizontal rule — a thematic break between sections
    class HorizontalRuleBlock < Block
      def self.semantic_type
        :horizontal_rule
      end

      def prose?
        false
      end
    end
  end
end
