# frozen_string_literal: true

require 'coridoc'

module Coridoc
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
          # @param model [Coridoc::Markdown::Base] Markdown model to transform
          # @return [Coridoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Coridoc::Markdown::Document
              transform_document(model)
            when Coridoc::Markdown::Heading
              transform_heading(model)
            when Coridoc::Markdown::Paragraph
              transform_paragraph(model)
            when Coridoc::Markdown::CodeBlock
              transform_code_block(model)
            when Coridoc::Markdown::Blockquote
              transform_blockquote(model)
            when Coridoc::Markdown::List
              transform_list(model)
            when Coridoc::Markdown::DefinitionList
              transform_definition_list(model)
            when Coridoc::Markdown::Table
              transform_table(model)
            when Coridoc::Markdown::Image
              transform_image(model)
            when Coridoc::Markdown::Link
              transform_link(model)
            when Coridoc::Markdown::Text
              Coridoc::CoreModel::TextContent.new(text: model.content)
            when Coridoc::Markdown::Emphasis
              transform_inline(model, 'italic')
            when Coridoc::Markdown::Strong
              transform_inline(model, 'bold')
            when Coridoc::Markdown::Code
              transform_inline(model, 'monospace')
            when Coridoc::Markdown::Highlight
              transform_inline(model, 'highlight')
            when Coridoc::Markdown::Strikethrough
              transform_inline(model, 'strikethrough')
            when Coridoc::Markdown::Footnote
              transform_footnote(model)
            when Coridoc::Markdown::FootnoteReference
              transform_footnote_reference(model)
            when Coridoc::Markdown::Abbreviation
              transform_abbreviation(model)
            when Coridoc::Markdown::HorizontalRule
              transform_horizontal_rule(model)
            when Coridoc::Markdown::Math
              transform_math(model)
            when Coridoc::Markdown::Extension
              transform_extension(model)
            when Coridoc::Markdown::AttributeList
              transform_attribute_list(model)
            when Coridoc::Markdown::Comment
              Coridoc::CoreModel::CommentBlock.new(content: model.text.to_s)
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

            Coridoc::CoreModel::DocumentElement.new(
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

            block = Coridoc::CoreModel::FrontmatterBlock::Codec.from_yaml(frontmatter_text)
            [block, *children]
          end

          def transform_heading(heading)
            Coridoc::CoreModel::SectionElement.new(
              level: heading.level,
              title: extract_text(heading.text),
              children: []
            )
          end

          def transform_paragraph(para)
            content = extract_text(para.text)

            Coridoc::CoreModel::ParagraphBlock.new(
              content: content,
              children: para.children.map { |child| transform(child) }
            )
          end

          def transform_code_block(block)
            Coridoc::CoreModel::SourceBlock.new(
              content: block.code.to_s,
              language: block.language
            )
          end

          def transform_blockquote(blockquote)
            Coridoc::CoreModel::QuoteBlock.new(
              content: blockquote.content.to_s
            )
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              nested = item.sublist ? transform_list(item.sublist) : nil
              Coridoc::CoreModel::ListItem.new(
                content: extract_text(item.text),
                marker: list.ordered ? '1.' : '*',
                nested_list: nested,
                children: inline_children(item)
              )
            end

            Coridoc::CoreModel::ListBlock.new(
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
              rows << Coridoc::CoreModel::TableRow.new(
                header: true,
                cells: table.headers.map do |h|
                  Coridoc::CoreModel::TableCell.new(content: h.to_s, header: true)
                end
              )
            end

            # Add data rows
            table.rows.each do |row|
              cells = if row.is_a?(Array)
                        row.map { |c| Coridoc::CoreModel::TableCell.new(content: c.to_s, header: false) }
                      else
                        row.to_s.split(' | ').map do |c|
                          Coridoc::CoreModel::TableCell.new(content: c.to_s, header: false)
                        end
                      end
              rows << Coridoc::CoreModel::TableRow.new(cells: cells)
            end

            Coridoc::CoreModel::Table.new(rows: rows)
          end

          def transform_image(image)
            Coridoc::CoreModel::Image.new(
              src: image.src,
              alt: image.alt.to_s
            )
          end

          def transform_link(link)
            Coridoc::CoreModel::LinkElement.new(
              target: link.url,
              content: extract_text(link.text)
            )
          end

          def transform_inline(inline, format_type)
            klass = Coridoc::CoreModel::InlineElement.format_type_class(format_type)
            klass.new(
              content: extract_text(inline.text)
            )
          end

          def transform_horizontal_rule(_rule)
            Coridoc::CoreModel::HorizontalRuleBlock.new
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |term|
              definitions = Array(term.definitions).map do |defn|
                defn.content.to_s
              end
              Coridoc::CoreModel::DefinitionItem.new(
                term: term.text.to_s,
                definitions: definitions
              )
            end

            Coridoc::CoreModel::DefinitionList.new(items: items)
          end

          def transform_footnote(fn)
            Coridoc::CoreModel::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink.nil? || fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Coridoc::CoreModel::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Coridoc::CoreModel::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end

          def transform_math(math)
            if math.inline?
              Coridoc::CoreModel::StemElement.new(
                content: math.content.to_s
              )
            else
              Coridoc::CoreModel::PassBlock.new(
                content: math.content.to_s,
                language: 'latexmath'
              )
            end
          end

          def transform_extension(ext)
            case ext.name.to_sym
            when :toc
              Coridoc::CoreModel::Toc.new
            when :comment
              Coridoc::CoreModel::CommentBlock.new(
                content: ext.content.to_s
              )
            when :nomarkdown
              Coridoc::CoreModel::PassBlock.new(
                content: ext.content.to_s
              )
            else
              # Unknown extension: keep the directive verbatim as
              # paragraph text. An empty content block would serialize
              # to nothing and vanish on re-parse; the verbatim
              # `{::name ...}` form reparses to the same paragraph.
              Coridoc::CoreModel::ParagraphBlock.new(
                content: ext.extension_syntax
              )
            end
          end

          def transform_attribute_list(attr_list)
            attrs = []
            attrs << Coridoc::CoreModel::ElementAttribute.new(name: 'id', value: attr_list.id.to_s) if attr_list.id
            attr_list.classes.each do |cls|
              attrs << Coridoc::CoreModel::ElementAttribute.new(name: 'class', value: cls.to_s)
            end
            attr_list.attributes.each do |nv|
              attrs << Coridoc::CoreModel::ElementAttribute.new(name: nv.name, value: nv.value)
            end

            Coridoc::CoreModel::StructuralElement.new(
              children: attrs
            )
          end

          def extract_title(doc)
            # Try to get title from first heading
            first_block = Array(doc.blocks).first
            return extract_text(first_block.text) if first_block.is_a?(Coridoc::Markdown::Heading)

            nil
          end
        end
      end
    end
  end
end
