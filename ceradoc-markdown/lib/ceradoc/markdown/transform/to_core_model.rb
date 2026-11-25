# frozen_string_literal: true

require 'ceradoc'

module Ceradoc
  module Markdown
    module Transform
      # Transforms Markdown models to CoreModel equivalents
      #
      # This transformer converts the format-specific Markdown model
      # to the canonical CoreModel representation.
      class ToCoreModel
        class << self
          include TextExtraction
          # Transform a Markdown model to CoreModel
          #
          # @param model [Ceradoc::Markdown::Base] Markdown model to transform
          # @return [Ceradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Ceradoc::Markdown::Document
              transform_document(model)
            when Ceradoc::Markdown::Heading
              transform_heading(model)
            when Ceradoc::Markdown::Paragraph
              transform_paragraph(model)
            when Ceradoc::Markdown::CodeBlock
              transform_code_block(model)
            when Ceradoc::Markdown::Blockquote
              transform_blockquote(model)
            when Ceradoc::Markdown::List
              transform_list(model)
            when Ceradoc::Markdown::DefinitionList
              transform_definition_list(model)
            when Ceradoc::Markdown::Table
              transform_table(model)
            when Ceradoc::Markdown::Image
              transform_image(model)
            when Ceradoc::Markdown::Link
              transform_link(model)
            when Ceradoc::Markdown::Text
              Ceradoc::CoreModel::TextContent.new(text: model.content)
            when Ceradoc::Markdown::Emphasis
              transform_inline(model, 'italic')
            when Ceradoc::Markdown::Strong
              transform_inline(model, 'bold')
            when Ceradoc::Markdown::Code
              transform_inline(model, 'monospace')
            when Ceradoc::Markdown::Highlight
              transform_inline(model, 'highlight')
            when Ceradoc::Markdown::Strikethrough
              transform_inline(model, 'strikethrough')
            when Ceradoc::Markdown::Footnote
              transform_footnote(model)
            when Ceradoc::Markdown::FootnoteReference
              transform_footnote_reference(model)
            when Ceradoc::Markdown::Abbreviation
              transform_abbreviation(model)
            when Ceradoc::Markdown::HorizontalRule
              transform_horizontal_rule(model)
            when Ceradoc::Markdown::Math
              transform_math(model)
            when Ceradoc::Markdown::Extension
              transform_extension(model)
            when Ceradoc::Markdown::AttributeList
              transform_attribute_list(model)
            when Ceradoc::Markdown::Comment
              Ceradoc::CoreModel::CommentBlock.new(content: model.text.to_s)
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end

          private

          def transform_document(doc)
            children = Array(doc.blocks).map { |block| transform(block) }
            children = prepend_frontmatter(children, doc.frontmatter)

            Ceradoc::CoreModel::DocumentElement.new(
              id: doc.id,
              title: extract_title(doc),
              children: children
            )
          end

          # If the Markdown document had raw frontmatter text, parse it
          # via Codec into a typed FrontmatterBlock and prepend it so
          # it participates in the standard block pipeline. Codec is
          # the single source of truth for YAML parsing (DRY/MECE).
          #
          # The block is prepended even when the YAML is malformed —
          # Codec returns an empty FrontmatterBlock in that case, which
          # preserves the signal "frontmatter was present but invalid"
          # for downstream consumers.
          def prepend_frontmatter(children, frontmatter_text)
            return children if frontmatter_text.nil? || frontmatter_text.strip.empty?

            block = Ceradoc::CoreModel::FrontmatterBlock::Codec.from_yaml(frontmatter_text)
            [block, *children]
          end

          def transform_heading(heading)
            Ceradoc::CoreModel::SectionElement.new(
              level: heading.level,
              title: extract_text(heading.text),
              children: []
            )
          end

          def transform_paragraph(para)
            content = extract_text(para.text)

            Ceradoc::CoreModel::ParagraphBlock.new(
              content: content,
              children: para.children.map { |child| transform(child) }
            )
          end

          def transform_code_block(block)
            Ceradoc::CoreModel::SourceBlock.new(
              content: block.code.to_s,
              language: block.language
            )
          end

          def transform_blockquote(blockquote)
            Ceradoc::CoreModel::QuoteBlock.new(
              content: blockquote.content.to_s
            )
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              nested = item.sublist ? transform_list(item.sublist) : nil
              Ceradoc::CoreModel::ListItem.new(
                content: extract_text(item.text),
                marker: list.ordered ? '1.' : '*',
                nested_list: nested,
                children: inline_children(item)
              )
            end

            Ceradoc::CoreModel::ListBlock.new(
              marker_type: list.ordered ? 'ordered' : 'unordered',
              items: items
            )
          end

          # Carry inline models (bold, italic, code) parsed from the item
          # text through to the CoreModel item as styled children.
          def inline_children(item)
            Array(item.children).map { |child| transform(child) }
          end

          def transform_table(table)
            # Convert Markdown table to CoreModel table
            rows = []

            # Add header row if present (GFM tables always lead with one)
            if table.headers.any?
              rows << Ceradoc::CoreModel::TableRow.new(
                header: true,
                cells: table.headers.map do |h|
                  Ceradoc::CoreModel::TableCell.new(content: h.to_s, header: true)
                end
              )
            end

            # Add data rows
            table.rows.each do |row|
              cells = if row.is_a?(Array)
                        row.map { |c| Ceradoc::CoreModel::TableCell.new(content: c.to_s, header: false) }
                      else
                        row.to_s.split(' | ').map do |c|
                          Ceradoc::CoreModel::TableCell.new(content: c.to_s, header: false)
                        end
                      end
              rows << Ceradoc::CoreModel::TableRow.new(cells: cells)
            end

            Ceradoc::CoreModel::Table.new(rows: rows)
          end

          def transform_image(image)
            Ceradoc::CoreModel::Image.new(
              src: image.src,
              alt: image.alt.to_s
            )
          end

          def transform_link(link)
            Ceradoc::CoreModel::LinkElement.new(
              target: link.url,
              content: extract_text(link.text)
            )
          end

          def transform_inline(inline, format_type)
            klass = Ceradoc::CoreModel::InlineElement.format_type_class(format_type)
            klass.new(
              content: extract_text(inline.text)
            )
          end

          def transform_horizontal_rule(_rule)
            Ceradoc::CoreModel::HorizontalRuleBlock.new
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |term|
              definitions = Array(term.definitions).map do |defn|
                defn.content.to_s
              end
              Ceradoc::CoreModel::DefinitionItem.new(
                term: term.text.to_s,
                definitions: definitions
              )
            end

            Ceradoc::CoreModel::DefinitionList.new(items: items)
          end

          def transform_footnote(fn)
            Ceradoc::CoreModel::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink.nil? || fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Ceradoc::CoreModel::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Ceradoc::CoreModel::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end

          def transform_math(math)
            if math.inline?
              Ceradoc::CoreModel::StemElement.new(
                content: math.content.to_s
              )
            else
              Ceradoc::CoreModel::PassBlock.new(
                content: math.content.to_s,
                language: 'latexmath'
              )
            end
          end

          def transform_extension(ext)
            case ext.name.to_sym
            when :toc
              Ceradoc::CoreModel::Toc.new
            when :comment
              Ceradoc::CoreModel::CommentBlock.new(
                content: ext.content.to_s
              )
            when :nomarkdown
              Ceradoc::CoreModel::PassBlock.new(
                content: ext.content.to_s
              )
            else
              # Unknown extensions: preserve content as a generic block
              Ceradoc::CoreModel::ParagraphBlock.new(
                content: ext.content.to_s
              )
            end
          end

          def transform_attribute_list(attr_list)
            attrs = []
            attrs << Ceradoc::CoreModel::ElementAttribute.new(name: 'id', value: attr_list.id.to_s) if attr_list.id
            attr_list.classes.each do |cls|
              attrs << Ceradoc::CoreModel::ElementAttribute.new(name: 'class', value: cls.to_s)
            end
            attr_list.attributes.each do |nv|
              attrs << Ceradoc::CoreModel::ElementAttribute.new(name: nv.name, value: nv.value)
            end

            Ceradoc::CoreModel::StructuralElement.new(
              children: attrs
            )
          end

          def extract_title(doc)
            # Try to get title from first heading
            first_block = Array(doc.blocks).first
            return extract_text(first_block.text) if first_block.is_a?(Ceradoc::Markdown::Heading)

            nil
          end
        end
      end
    end
  end
end
