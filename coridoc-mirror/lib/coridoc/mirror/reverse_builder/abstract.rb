# frozen_string_literal: true

module Coridoc
  module Mirror
    module ReverseBuilder
      class Abstract < Base
        def build(node)
          CoreModel::AbstractBlock.new(
            title: node.attrs&.title,
            id: node.attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
