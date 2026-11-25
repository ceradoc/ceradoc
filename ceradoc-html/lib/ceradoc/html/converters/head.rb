# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Head < Base
        INSTANCE = new

        def to_ceradoc(node, _state = {})
          title = extract_title(node)
          # Use DocumentElement for document header
          Ceradoc::CoreModel::DocumentElement.new(
            title: title,
            level: 0
          )
        end

        def extract_title(node)
          title = node.at('./title')
          return '(???)' if title.nil?

          title.text
        end
      end

      register :head, Head::INSTANCE
    end
  end
end
