# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Aside < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          content = treat_children_coridoc(node, state)
          Coridoc::CoreModel::SidebarBlock.new(
            children: content
          )
        end
      end

      register :aside, Aside::INSTANCE
    end
  end
end
