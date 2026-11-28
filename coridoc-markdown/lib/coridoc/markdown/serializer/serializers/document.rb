# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Document < ElementSerializer
          handles_type ::Coridoc::Markdown::Document

          def call(element, ctx)
            body = join_blocks(element.blocks, ctx)
            return body unless element.frontmatter && !element.frontmatter.empty?

            "---\n#{element.frontmatter}---\n\n#{body}".strip
          end

          private

          # Adjacent lists need a blank-line RUN between them: the parser
          # reads a single blank line as a loose-item separator (the lists
          # fold back into one) and only two blanks as a block boundary,
          # which is what the model keeps apart.
          def join_blocks(blocks, ctx)
            blocks.each_with_index.map do |block, index|
              separator =
                if index.zero?
                  ''
                elsif adjacent_lists?(blocks[index - 1], block)
                  "\n\n\n"
                else
                  "\n\n"
                end
              "#{separator}#{ctx.serialize(block)}"
            end.join
          end

          def adjacent_lists?(left, right)
            left.is_a?(Coridoc::Markdown::List) && right.is_a?(Coridoc::Markdown::List)
          end
        end
      end
    end
  end
end
