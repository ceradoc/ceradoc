# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class Header < Base
        def build(node)
          attrs = node.attrs
          CoreModel::HeaderElement.new(
            id: attrs&.id,
            title: attrs&.title,
            level: attrs&.level,
            content: attrs&.title,
            children: build_content(node)
          )
        end
      end
    end
  end
end
