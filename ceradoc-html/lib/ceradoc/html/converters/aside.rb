# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Aside < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          content = treat_children_ceradoc(node, state)
          Ceradoc::CoreModel::SidebarBlock.new(
            children: content
          )
        end
      end

      register :aside, Aside::INSTANCE
    end
  end
end
