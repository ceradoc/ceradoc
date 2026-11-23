# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Q < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          content = treat_children_coridoc(node, state)
          cite = node['cite']

          Coridoc::CoreModel::InlineElement.new(
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
