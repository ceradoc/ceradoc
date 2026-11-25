# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Table < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          id = node['id']
          title = extract_title(node)
          content = treat_children_ceradoc(node, state)

          # Apply frame and grid attributes if available
          frame_attr = frame(node)
          grid_attr = rules(node)

          Ceradoc::CoreModel::Table.new(
            title: title,
            rows: content,
            id: id,
            frame: frame_attr,
            grid: grid_attr
          )
        end

        def extract_title(node)
          title = node.at('./caption')
          return nil if title.nil?

          title.text.strip
        end

        def frame(node)
          case node['frame']
          when 'void'
            'none'
          when 'hsides'
            'topbot'
          when 'vsides'
            'sides'
          when 'box', 'border'
            'all'
          end
        end

        def rules(node)
          case node['rules']
          when 'all'
            'all'
          when 'rows'
            'rows'
          when 'cols'
            'cols'
          when 'none'
            'none'
          end
        end
      end

      register :table, Table::INSTANCE
    end
  end
end
