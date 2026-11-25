# frozen_string_literal: true

require 'ceradoc/markdown'

module Ceradoc
  module Markdown
    # Opt-in semantic inline grammar. Reuses the shipped emphasis/code parser,
    # adding direct links and images that the generic inline grammar leaves text.
    class MetanormaInlineParser < Parser::InlineParser
      rule(:semantic_label) { (str(']').absent? >> any).repeat }
      rule(:semantic_destination) { (match['\\s()'].absent? >> any).repeat(1) }
      rule(:semantic_image) do
        str('![').ignore >> semantic_label.as(:semantic_alt) >> str('](').ignore >>
          semantic_destination.as(:semantic_src) >> str(')').ignore
      end
      rule(:semantic_link) do
        str('[').ignore >> semantic_label.as(:semantic_label) >> str('](').ignore >>
          semantic_destination.as(:semantic_target) >> str(')').ignore
      end
      rule(:element) { semantic_image | semantic_link | code_span | checked_delimiter_run }
    end
  end
end
