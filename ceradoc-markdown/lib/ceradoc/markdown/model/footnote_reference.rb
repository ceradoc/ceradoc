# frozen_string_literal: true

module Ceradoc
  module Markdown
    # FootnoteReference model representing an inline footnote reference.
    #
    # Syntax: `[^name]` anywhere in text
    #
    # @example
    #   ref = Ceradoc::Markdown::FootnoteReference.new(id: "1")
    #
    class FootnoteReference < Base
      # The footnote identifier
      attribute :id, :string
    end
  end
end
