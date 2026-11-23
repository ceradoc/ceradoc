# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Div < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          id = node['id']
          contents = treat_children_coridoc(node, state)

          Coridoc::CoreModel::OpenBlock.new(
            children: contents,
            id: id
          )
        end
      end

      register :div, Div::INSTANCE
    end
  end
end
