# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Div < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          id = node['id']
          contents = treat_children_ceradoc(node, state)

          Ceradoc::CoreModel::OpenBlock.new(
            children: contents,
            id: id
          )
        end
      end

      register :div, Div::INSTANCE
    end
  end
end
