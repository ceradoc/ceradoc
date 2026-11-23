# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module List
        # Unordered (bulleted) list for AsciiDoc documents.
        #
        # Unordered lists use asterisk markers (*, **, ***) and are
        # typically used for non-sequential items where order doesn't matter.
        #
        # @example Create an unordered list
        #   list = Coridoc::AsciiDoc::Model::List::Unordered.new
        #   item = Coridoc::AsciiDoc::Model::ListItem.new
        #   item.content = [Coridoc::AsciiDoc::Model::TextElement.new("Bullet point")]
        #   list.items << item
        #
        # @see Coridoc::AsciiDoc::Model::List::Core Base list class
        # @see Coridoc::AsciiDoc::Model::List::Ordered Ordered (numbered) lists
        #
        class Unordered < Core
          # Generate the prefix marker for this list level
          #
          # @return [String] The prefix marker (e.g., "*", "**", "***")
          def prefix
            return marker if marker

            '*' * [ol_count, 1].max
          end
        end
      end
    end
  end
end
