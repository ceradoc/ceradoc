# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Figure < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          id = node['id']
          title_content = extract_title(node)
          content = treat_children_ceradoc(node, state)

          # Use CoreModel::ExampleBlock for example/figure
          Ceradoc::CoreModel::ExampleBlock.new(
            title: extract_text_from_content(title_content),
            children: content,
            id: id
          )
        end

        def extract_title(node)
          title = node.at('./figcaption')
          return '' if title.nil?

          treat_children_ceradoc(title, {})
        end
      end

      register :figure, Figure::INSTANCE
    end
  end
end
