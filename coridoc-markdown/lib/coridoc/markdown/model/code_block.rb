# frozen_string_literal: true

module Coridoc
  module Markdown
    # CodeBlock model representing a fenced code block.
    #
    # @example Create a code block
    #   code = Coridoc::Markdown::CodeBlock.new(
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
