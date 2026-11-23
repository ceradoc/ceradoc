# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Td < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          colspan = node['colspan']&.to_i
          rowspan = node['rowspan']&.to_i
          alignment = extract_alignment(node)

          singlepara = node.elements.size == 1 && node.elements.first.name == 'p'
          state[:tdsinglepara] = singlepara if singlepara

          content = treat_children_coridoc(node, state)

          Coridoc::CoreModel::TableCell.new(
            content: extract_text_from_content(content),
            alignment: alignment,
            colspan: colspan && colspan > 1 ? colspan : nil,
            rowspan: rowspan && rowspan > 1 ? rowspan : nil,
            header: node.name == 'th'
          )
        end

        def extract_alignment(node)
          align = node['align']
          case align
          when 'left' then 'left'
          when 'center' then 'center'
          when 'right' then 'right'
          end
        end
      end

      register :td, Td::INSTANCE
      register :th, Td::INSTANCE
    end
  end
end
