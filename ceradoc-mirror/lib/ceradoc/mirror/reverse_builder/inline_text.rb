# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class InlineText < Base
        def build(node)
          children = build_inline_children(node)
          # Parse convention: display text of the runs — marked labels
          # included (e.g. a dt term like `--verbose, -v` with code
          # marks still flattens with its label text).
          text = children.map(&:display_text).join
          CoreModel::InlineElement.new(content: text)
        end
      end
    end
  end
end
