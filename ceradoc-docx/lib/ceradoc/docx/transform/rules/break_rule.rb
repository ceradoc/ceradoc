# frozen_string_literal: true

module Ceradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:br (Break) elements.
        #
        # Page breaks become CoreModel::Block (page_break).
        # Line breaks become CoreModel::InlineElement (hard_line_break).
        class BreakRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::Break) &&
              element.is_a?(Uniword::Wordprocessingml::Break)
          end

          def apply(brk, _context)
            if brk.type == 'page'
              Ceradoc::CoreModel::Block.new(block_semantic_type: 'page_break')
            else
              Ceradoc::CoreModel::InlineElement.new(
                format_type: 'hard_line_break'
              )
            end
          end
        end
      end
    end
  end
end
