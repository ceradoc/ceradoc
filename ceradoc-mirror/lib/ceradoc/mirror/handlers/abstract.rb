# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      module Abstract
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Abstract.new(
            attrs: Node::Abstract::Attrs.new(id: element.id, title: element.title),
            content: content
          )
        end
      end
    end
  end
end
