# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class Comment < Base
        def build(node)
          attrs = node.attrs
          if attrs&.block
            CoreModel::CommentBlock.new(content: attrs&.text)
          else
            CoreModel::CommentLine.new(text: attrs&.text)
          end
        end
      end
    end
  end
end
