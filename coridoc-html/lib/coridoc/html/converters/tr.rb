# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Tr < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          content = treat_children_coridoc(node, state)
          header = table_header_row?(node)
          # Use CoreModel::TableRow with cells (not columns)
          Coridoc::CoreModel::TableRow.new(
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
