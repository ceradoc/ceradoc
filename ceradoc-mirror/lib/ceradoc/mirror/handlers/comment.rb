# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      # Comment handlers. Comments are not rendered, but they ARE part
      # of the document tree — dropping them at the seam shifts every
      # following sibling positionally on the reverse side, so the wire
      # carries a typed comment node.
      module Comment
        def self.call(element, *)
          Node::Comment.new(
            attrs: Node::Comment::Attrs.new(
              text: comment_text(element),
              block: !element.is_a?(CoreModel::CommentLine)
            )
          )
        end

        def self.comment_text(element)
          if element.is_a?(CoreModel::CommentLine)
            element.text
          else
            element.content
          end
        end
      end
    end
  end
end
