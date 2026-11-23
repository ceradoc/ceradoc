# frozen_string_literal: true

module Coridoc
  module Markdown
    # Blockquote model representing a Markdown blockquote (> prefix).
    #
    # @example Create a blockquote
    #   quote = Coridoc::Markdown::Blockquote.new(
    #     content: "This is a quoted text."
    #   )
    #
    class Blockquote < Base
      attribute :content, :string
    end
  end
end
