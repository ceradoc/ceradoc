# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class TableCell < Base
        def build(node)
          attrs = node.attrs
          children = build_inline_children(node)
          CoreModel::TableCell.new(
            # Cells carry BOTH shapes like the forward parse: structured
            # children (which keep inline images as image nodes — never
            # flatten them to alt text) and the flattened display text.
            content: children.map(&:display_text).join,
            children: children,
            header: attrs&.header || false,
            colspan: attrs&.colspan,
            rowspan: attrs&.rowspan,
            alignment: attrs&.alignment
          )
        end
      end
    end
  end
end
