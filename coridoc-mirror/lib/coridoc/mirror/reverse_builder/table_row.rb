# frozen_string_literal: true

module Coridoc
  module Mirror
    module ReverseBuilder
      class TableRow < Base
        def build(node)
          cells = build_content(node).select { |c| c.is_a?(CoreModel::TableCell) }
          CoreModel::TableRow.new(cells: cells)
        end
      end
    end
  end
end
