# frozen_string_literal: true

module Coridoc
  module Mirror
    module ReverseBuilder
      class TableBody < Base
        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end
    end
  end
end
