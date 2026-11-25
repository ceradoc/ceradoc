# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Tr < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          content = treat_children_ceradoc(node, state)
          header = table_header_row?(node)
          # Use CoreModel::TableRow with cells (not columns)
          Ceradoc::CoreModel::TableRow.new(
            cells: content,
            header: header
          )
        end

        def table_header_row?(node)
          node.previous_element.nil?
        end
      end

      register :tr, Tr::INSTANCE
    end
  end
end
