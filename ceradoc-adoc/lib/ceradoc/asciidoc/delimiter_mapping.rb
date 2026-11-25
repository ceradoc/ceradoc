# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module DelimiterMapping
      CHAR_TO_SEMANTIC = {
        '-' => :source_code,
        '=' => :example,
        '_' => :quote,
        '*' => :sidebar,
        '.' => :literal,
        '+' => :pass
      }.freeze
    end
  end
end
