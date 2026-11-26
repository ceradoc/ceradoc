# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class ListItem < Base
        LIST_TYPES = %w[bullet_list ordered_list].freeze
        private_constant :LIST_TYPES

        def build(node)
          attrs = node.attrs
          children = build_inline_children(node)
          # Parse convention: the item's content string is the display
          # text of its runs (marked labels included), not just the raw
          # TextContent runs.
          text = children.map(&:display_text).join

          CoreModel::ListItem.new(
            content: text,
            # The nested list is carried in #nested_list, not as a child
            # run — the forward parse never places it in #children.
            children: children.reject { |c| c.is_a?(CoreModel::ListBlock) },
            nested_list: find_nested_list(node),
            marker: attrs&.marker
          )
        end

        private

        def find_nested_list(node)
          node.content&.each do |child|
            next unless child.is_a?(Node)
            return build_node(child) if LIST_TYPES.include?(child.type)
          end
          nil
        end
      end
    end
  end
end
