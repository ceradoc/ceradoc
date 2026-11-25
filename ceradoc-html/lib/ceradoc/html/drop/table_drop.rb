# frozen_string_literal: true

module Ceradoc
  module Html
    module Drop
      class TableDrop < Base
        def rows
          children_to_liquid(@model.rows)
        end
      end

      DropFactory.register(CoreModel::Table, TableDrop)
    end
  end
end
