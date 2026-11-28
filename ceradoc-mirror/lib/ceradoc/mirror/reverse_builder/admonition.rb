# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class Admonition < Base
        def build(node)
          children = build_inline_children(node)
          CoreModel::AnnotationBlock.new(
            annotation_type: node.attrs&.admonition_type,
            # The forward parse carries both shapes on an admonition:
            # structured children next to the flattened content string.
            content: children.map(&:display_text).join,
            children: children
          )
        end
      end
    end
  end
end
