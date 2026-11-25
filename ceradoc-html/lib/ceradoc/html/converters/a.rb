# frozen_string_literal: true

require 'ceradoc'

module Ceradoc
  module Html
    module Converters
      class A < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          # Use treat_children_ceradoc to get CoreModel elements
          content = treat_children_ceradoc(node, state)

          href  = node['href']
          title = extract_title(node)
          id = node['id'] || node['name']

          id = id&.gsub(/\s/, '')&.gsub(/__+/, '_')
          id = nil if id&.empty?

          return nil if /^_Toc\d+$|^_GoBack$/.match?(id)

          # For inline anchors - return CoreModel InlineElement with format_type "anchor"
          if id
            return Ceradoc::CoreModel::InlineElement.new(
              format_type: 'anchor',
              target: id
            )
          end

          # For cross-references
          if href.to_s.start_with?('#')
            ref_id = href.sub(/^#/, '').gsub(/\s/, '').gsub(/__+/, '_')
            content_str = extract_text_from_content(content)
            return Ceradoc::CoreModel::CrossReferenceElement.new(
              target: ref_id,
              content: content_str.strip.empty? ? nil : content_str.strip
            )
          end

          return nil if href.to_s.empty?

          # For links
          ambigous_characters = /[\w.?&#=%;\[\u{ff}-\u{10ffff}]/
          right_constrain = textnode_after_start_with?(node, ambigous_characters)

          content_str = extract_text_from_content(content)

          out = []
          # Add leading space if needed
          if textnode_before_end_with?(node, ambigous_characters)
            out << Ceradoc::CoreModel::TextElement.new(
              content: ' '
            )
          end

          # Create link element
          link = Ceradoc::CoreModel::LinkElement.new(
            target: href,
            content: content_str.strip,
            metadata: {
              title: (title.strip unless title.to_s.strip.empty?),
              right_constrain: right_constrain
            }.compact
          )
          out << link

          # Return single element or array
          out.length == 1 ? out.first : out
        end
      end

      register :a, A::INSTANCE
    end
  end
end
