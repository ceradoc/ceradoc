# frozen_string_literal: true

module Ceradoc
  module Markdown
    # Blockquote model representing a Markdown blockquote (> prefix).
    #
    # @example Create a blockquote
    #   quote = Ceradoc::Markdown::Blockquote.new(
    #     content: "This is a quoted text."
    #   )
    #
    class Blockquote < Base
      attribute :content, :string
    end
  end
end
