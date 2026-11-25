# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Q < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          content = treat_children_ceradoc(node, state)
          cite = node['cite']

          Ceradoc::CoreModel::InlineElement.new(
            format_type: 'quotation',
            nested_elements: content,
            content: extract_text_from_content(content),
            target: cite
          )
        end
      end

      register :q, Q::INSTANCE
    end
  end
end
