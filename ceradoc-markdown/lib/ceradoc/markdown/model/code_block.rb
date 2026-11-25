# frozen_string_literal: true

module Ceradoc
  module Markdown
    # CodeBlock model representing a fenced code block.
    #
    # @example Create a code block
    #   code = Ceradoc::Markdown::CodeBlock.new(
    #     language: "ruby",
    #     code: "puts 'Hello World'"
    #   )
    #
    class CodeBlock < Base
      attribute :language, :string
      attribute :code, :string
    end
  end
end
