# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      # Comment block element for AsciiDoc documents.
      #
      # Comment blocks contain multi-line comments that are not part
      # of the final document output.
      #
      # @!attribute [r] text
      #   @return [String] The comment text
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create a comment block
      #   comment = Coridoc::AsciiDoc::Model::CommentBlock.new
      #   comment.text = "This is a multi-line comment"
      #
      # @see Coridoc::AsciiDoc::Model::CommentLine Single-line comments
      #
      class CommentBlock < Base
        def block_level?
          true
        end

        attribute :text, :string
        attribute :line_break, :string, default: -> { "\n" }
      end
    end
  end
end
