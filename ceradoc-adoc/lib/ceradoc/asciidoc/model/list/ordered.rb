# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module List
        # Ordered (numbered) list for AsciiDoc documents.
        #
        # Ordered lists use numeric markers (1, 2, 3...) or custom markers
        # and are typically used for sequential items.
        #
        # @example Create an ordered list
        #   list = Ceradoc::AsciiDoc::Model::List::Ordered.new
        #   item = Ceradoc::AsciiDoc::Model::ListItem.new
        #   item.content = [Ceradoc::AsciiDoc::Model::TextElement.new("First item")]
        #   list.items << item
        #
        # @see Ceradoc::AsciiDoc::Model::List::Core Base list class
        # @see Ceradoc::AsciiDoc::Model::List::Unordered Unordered (bulleted) lists
        #
        class Ordered < Core
          # Generate the prefix marker for this list level
          #
          # @return [String] The prefix marker (e.g., ".", "..", "...")
          def prefix
            return marker if marker

            '.' * [ol_count, 1].max
          end
        end
      end
    end
  end
end
