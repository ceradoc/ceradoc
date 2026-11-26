# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # Hoists attribute-entry lines out of paragraphs into the document's
      # attribute block (#376 kotoshu fixture).
      #
      # The grammar's paragraph rule soft-wraps any following line into an
      # open paragraph, so an attribute entry (`:toc:`) that follows an
      # unrecognised author line is captured as a paragraph line instead of
      # matching the document-level `document_attributes` alternative. The
      # corpus shows the glued shape is stable at the tree level — one
      # TextElement per source line — so the transform layer can recover
      # the attribute without touching the grammar: a TextElement whose
      # entire content is an attribute entry (`:key:` / `:key: value`) is
      # pulled out of its paragraph and appended to
      # +Model::DocumentAttributes+, which the existing pipeline already
      # maps to +CoreModel::Metadata+ and serializes before the body.
      #
      # Key charset mirrors Parser::DocumentAttributes#attribute_name.
      module DocumentAttributeEntries
        KEY_PATTERN = /[a-zA-Z0-9_-]+/
        ENTRY_PATTERN = /\A:(?<key>#{KEY_PATTERN}):(?<value>[^\n]*)\z/

        module_function

        def hoist!(document)
          entries = []
          document.sections = walk(document.sections, entries) if document.respond_to?(:sections)
          document.contents = walk(document.contents, entries) if document.respond_to?(:contents)
          append_entries(document, entries)
          document
        end

        def walk(nodes, entries)
          Array(nodes).filter_map do |node|
            case node
            when Ceradoc::AsciiDoc::Model::Paragraph
              clean_paragraph(node, entries)
            when Ceradoc::AsciiDoc::Model::Section
              node.contents = walk(node.contents, entries) if node.respond_to?(:contents)
              node.sections = walk(node.sections, entries) if node.respond_to?(:sections)
              node
            else
              node
            end
          end
        end

        def clean_paragraph(paragraph, entries)
          items = Array(paragraph.content)
          kept = items.reject { |item| entry_item?(item, entries) }
          return nil if kept.empty? && items.any?

          paragraph.content = kept if kept.size != items.size
          paragraph
        end

        def entry_item?(item, entries)
          text = entry_text(item)
          return false unless text

          match = ENTRY_PATTERN.match(text)
          return false unless match

          entries << Ceradoc::AsciiDoc::Model::Attribute.new(
            key: match[:key], value: match[:value].sub(/\A\s+/, '')
          )
          true
        end

        def entry_text(item)
          return nil unless item.is_a?(Ceradoc::AsciiDoc::Model::TextElement)
          return nil unless item.content.is_a?(String)

          item.content
        end

        def append_entries(document, entries)
          return if entries.empty?

          document.document_attributes ||= Ceradoc::AsciiDoc::Model::DocumentAttributes.new(data: [])
          document.document_attributes.data = Array(document.document_attributes.data) + entries
        end
      end
    end
  end
end
