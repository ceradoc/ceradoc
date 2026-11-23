# frozen_string_literal: true

module Coridoc
  module CoreModel
    # Comment block — editorial or hidden comments
    class CommentBlock < Block
      def self.semantic_type
        :comment
      end

      def body_content?
        false
      end
    end
  end
end
