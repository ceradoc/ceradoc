# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # List construction for the AsciiDoc view: nested lists flatten
      # into the item stream with depth markers so AsciiDoc reads them
      # as nested rather than sibling lists (#68) — a marker-type
      # change alone signals nesting; same-type nesting goes one level
      # deeper.
      module ListBuilding
        def transform_list(list, depth = 1)
          items = []
          Array(list.items).each do |item|
            nested_blocks = [item.nested_list,
                             *Array(item.children).grep(CoreModel::ListBlock)].compact
            text = inline_text(item)
            attached = attached_blocks(item)
            if text_blank?(text) && attached.empty? && nested_blocks.any?
              # A wrapper item whose only content is its nested list
              # cannot render as a deeper list in AsciiDoc (lists start
              # at level 1, #68), so splice the nested list at this depth.
              nested_blocks.each do |child|
                child_depth = child.marker_type == list.marker_type ? depth : 1
                items.concat(transform_list(child, child_depth).items)
              end
              next
            end
            items << Ceradoc::AsciiDoc::Model::List::Item.new(
              content: text,
              marker: item.marker || (default_marker(list.marker_type) * depth),
              attached: attached
            )
            nested_blocks.each do |child|
              child_depth = child.marker_type == list.marker_type ? depth + 1 : 1
              items.concat(transform_list(child, child_depth).items)
            end
          end

          case list.marker_type
          when 'ordered'
            Ceradoc::AsciiDoc::Model::List::Ordered.new(items: items)
          when 'definition'
            Ceradoc::AsciiDoc::Model::List::Definition.new(items: items)
          else
            Ceradoc::AsciiDoc::Model::List::Unordered.new(items: items)
          end
        end

        # Inline children render on the item line; CoreModel::Block
        # children become attached blocks (`+` continuations) instead of
        # being glued into the item text.
        #
        # When the item carries markup (InlineElement children), rebuild
        # the line inline-faithfully via create_text_elements — the same
        # path paragraphs use — so monospace/bold/link markup and their
        # constraint survive into the serialized item (#376). Plain-text
        # items keep the flat string form.
        def inline_text(item)
          case (rc = item.renderable_content)
          when String then rc
          when Array
            inline_children = rc.reject do |child|
              child.is_a?(CoreModel::Block) || child.is_a?(CoreModel::ListBlock)
            end
            if inline_children.any?(CoreModel::InlineElement)
              Ceradoc::AsciiDoc::Model::TextElement.new(
                content: FromCoreModel.create_text_elements(inline_children)
              )
            else
              plain_text(inline_children)
            end
          else
            ''
          end
        end

        def plain_text(children)
          children.each_with_object(+'') do |child, out|
            out << case child
                   when CoreModel::TextContent then child.text.to_s
                   when String then child
                   when CoreModel::Base then child.flat_text.to_s
                   end
          end
        end

        # Item content is a flat String or an inline-faithful
        # Model::TextElement; both count as "empty" when they carry no
        # visible text.
        def text_blank?(text)
          case text
          when String then text.empty?
          when Ceradoc::AsciiDoc::Model::TextElement
            Array(text.content).join.empty?
          else
            text.nil?
          end
        end

        def attached_blocks(item)
          Array(item.children)
            .grep(CoreModel::Block)
            .flat_map { |block| FromCoreModel.flatten_children([block]) }
        end

        def default_marker(marker_type)
          case marker_type
          when 'ordered' then '.'
          else '*'
          end
        end
      end
    end
  end
end
