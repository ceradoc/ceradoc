# frozen_string_literal: true

module Ceradoc
  module Markdown
    # Link model representing a Markdown link [text](url).
    #
    # @example Create a link
    #   link = Ceradoc::Markdown::Link.new(
    #     text: "Example",
    #     url: "https://example.com"
    #   )
    #
    class Link < Base
      attribute :text, :string
      attribute :url, :string
      attribute :title, :string # Optional title
    end
  end
end
