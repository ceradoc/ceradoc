# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Figure < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          id = node['id']
          title_content = extract_title(node)
          content = treat_children_coridoc(node, state)

          # Use CoreModel::ExampleBlock for example/figure
          Coridoc::CoreModel::ExampleBlock.new(
            title: extract_text_from_content(title_content),
            children: content,
            id: id
          )
        end

        def extract_title(node)
          title = node.at('./figcaption')
          return '' if title.nil?

          treat_children_coridoc(title, {})
        end
      end

      register :figure, Figure::INSTANCE
    end
  end
end
