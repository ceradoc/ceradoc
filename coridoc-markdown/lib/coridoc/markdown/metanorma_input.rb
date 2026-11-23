# frozen_string_literal: true

require 'coridoc/markdown'
require 'coridoc'
require 'coridoc/markdown/metanorma_inline_parser'

module Coridoc
  module Markdown
    # Semantic-output adapter. Existing generic frontend conversion is unchanged.
    class MetanormaInput < Transform::ToCoreModel
      class << self
        def transform(model)
          result = case model
                   when Paragraph
                     children = model.text ? inline_nodes(model.text) : Array(model.children).map { |child| transform(child) }
                     if children.one? && children.first.is_a?(CoreModel::Image)
                       children.first
                     else
                       CoreModel::ParagraphBlock.new(content: model.text, children: children)
                     end
                   when Math
                     if model.inline?
                       CoreModel::StemElement.new(content: model.content, stem_type: 'LaTeX')
                     else
                       CoreModel::StemBlock.new(content: model.content.to_s.sub(/\r?\n\z/, ''), language: 'latex')
                     end
                   when CrossReference
                     CoreModel::CrossReferenceElement.new(target: model.target, content: model.text)
                   when HardLineBreak
                     CoreModel::HardLineBreakElement.new
                   when Admonition
                     CoreModel::AnnotationBlock.new(annotation_type: model.admonition_type, title: model.title,
                                                    content: model.content, children: Array(model.children).map { |child| transform(child) })
                   when ExampleBlock
                     CoreModel::ExampleBlock.new(title: model.caption, content: model.content,
                                                 children: Array(model.children).map { |child| transform(child) })
                   when Extension
                     CoreModel::Block.new(block_semantic_type: "markdown_extension:#{model.name}", content: model.content)
                   when Blockquote
                     inner = transform(Markdown.parse(model.content.to_s))
                     CoreModel::QuoteBlock.new(children: inner.children)
                   else
                     super
                   end
          if model.is_a?(Base) && result.is_a?(CoreModel::Base)
            result.id = model.id if model.id
            attrs = Array(model.attributes).map { |nv| CoreModel::ElementAttribute.new(name: nv.name, value: nv.value) }
            attrs += Array(model.classes).map { |cls| CoreModel::ElementAttribute.new(name: 'class', value: cls) }
            result.element_attributes = attrs unless attrs.empty?
          end
          result.start = model.start_number if model.is_a?(List) && model.ordered
          result.caption = model.title if model.is_a?(Image)
          result
        end

        private

        def transform_document(doc)
          children = []
          Array(doc.blocks).each do |block|
            if block.is_a?(AttributeList)
              meaningful = Array(block.attributes).any? { |item| item.name || item.value }
              raise Coridoc::Metanorma::UnsupportedNode, 'Only an ID on the preceding Markdown block is representable at markdown/attributes' if !block.id || block.name || !Array(block.classes).empty? || meaningful || children.empty?

              previous = children.last
              raise Coridoc::Metanorma::UnsupportedNode, 'Conflicting Markdown block IDs at markdown/attributes' if previous.id && previous.id != block.id

              previous.id = block.id
            else
              children << transform(block)
            end
          end
          CoreModel::DocumentElement.new(id: doc.id, title: extract_title(doc),
                                         children: prepend_frontmatter(children, doc.frontmatter))
        end

        def inline_nodes(text)
          raw_inline_nodes(MetanormaInlineParser.new.parse(text.to_s))
        end

        def raw_inline_nodes(nodes)
          (nodes.is_a?(Array) ? nodes : [nodes]).map do |node|
            if node.is_a?(Hash) && node.key?(:semantic_src)
              CoreModel::Image.new(src: node[:semantic_src].to_s, alt: node[:semantic_alt].to_s)
            elsif node.is_a?(Hash) && node.key?(:semantic_target)
              target = node[:semantic_target].to_s
              label = node[:semantic_label] == [] ? '' : node[:semantic_label].to_s
              if target.start_with?('#')
                CoreModel::CrossReferenceElement.new(target: target.delete_prefix('#'),
                                                     children: label.empty? ? [] : inline_nodes(label))
              else
                CoreModel::LinkElement.new(target: target, children: inline_nodes(label))
              end
            elsif node.is_a?(Hash) && node.key?(:strong)
              CoreModel::BoldElement.new(children: raw_inline_nodes(node[:strong]))
            elsif node.is_a?(Hash) && node.key?(:emph)
              CoreModel::ItalicElement.new(children: raw_inline_nodes(node[:emph]))
            elsif node.is_a?(Hash) && node.key?(:code)
              CoreModel::MonospaceElement.new(content: node[:code].to_s)
            else
              text = node.is_a?(Hash) && node.key?(:text) ? node[:text].to_s : node.to_s
              raise Coridoc::Metanorma::UnsupportedNode, "Unknown Markdown inline node at markdown/inline: #{node.keys}" if node.is_a?(Hash) && !node.key?(:text)
              raise Coridoc::Metanorma::UnsupportedNode, 'Markdown inline syntax is outside the semantic grammar at markdown/inline' if text.match?(%r{\]\(|\[\^|\$\$.*\$\$|<[A-Za-z!/][^>]*>}m)

              CoreModel::TextContent.new(text: text)
            end
          end
        end

        def inline_children(item)
          inline_nodes(extract_text(item.text))
        end

        def transform_table(model)
          result = super
          Array(result.rows).each do |row|
            Array(row.cells).each { |cell| cell.children = inline_nodes(cell.content) }
          end
          result
        end

        def transform_inline(model, format_type)
          result = super
          # Code spans carry literal text; other marks can nest inline nodes.
          result.children = inline_nodes(model.text) unless format_type == 'monospace'
          result
        end
      end
    end
  end
end
