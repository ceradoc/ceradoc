# frozen_string_literal: true

module Ceradoc
  module Metanorma
    class Builder
      # Typed block construction, shared by source frontends and CoreModel callers.
      module BlockBuilder
        private

        def block(parent, node, path)
          case node
          when CORE::StemBlock
            formula_block(parent, node, path)
          when CORE::QuoteBlock, CORE::ExampleBlock
            container_block(parent, node, path)
          when CORE::ParagraphBlock
            unsupported(node, path, 'paragraph caption') if node.title
            append(parent, 'p', paragraph(node, path))
          when CORE::DefinitionList
            definition_list_block(parent, node, path)
          when CORE::ListBlock
            list_block(parent, node, path)
          when CORE::Table
            append(parent, 'table', table(node, path))
          when CORE::Image
            image_block(parent, node, path)
          when CORE::SourceBlock, CORE::ListingBlock
            sourcecode_block(parent, node, path)
          when CORE::AnnotationBlock
            note_block(parent, node, path)
          when CORE::Block
            if node.resolve_semantic_type == :paragraph
              append(parent, 'p', paragraph(node, path))
            else
              unsupported(node, path, "block type #{node.resolve_semantic_type}")
            end
          else
            unsupported(node, path)
          end
        end

        def formula_block(parent, node, path)
          stem = C::TextElements::StemElement.new(stem_type: node.language)
          text = node.content || Array(node.lines).join("\n")
          if node.language.to_s.downcase.include?('latex')
            stem.latexmath = C::TextElements::LatexmathElement.new(value: text)
          elsif node.language.to_s.downcase == 'asciimath'
            stem.asciimath = C::TextElements::Asciiml.new(value: text)
          else
            unsupported(node, path, "math language #{node.language}")
          end
          append(parent, 'formula', C::AncillaryBlocks::FormulaBlock.new(id: id(node, path), stem: stem))
        end

        def container_block(parent, node, path)
          tag, klass = node.is_a?(CORE::QuoteBlock) ? ['quote', C::MultiParagraph::QuoteBlock] : ['example', C::AncillaryBlocks::ExampleBlock]
          result = klass.new(id: id(node, path))
          result.name = [C::Inline::NameWithIdElement.new(text: node.title)] if node.title && node.is_a?(CORE::ExampleBlock)
          result.author = C::MultiParagraph::QuoteAuthorElement.new(text: node.attribution) if node.is_a?(CORE::QuoteBlock) && node.attribution
          children = Array(node.children)
          if children.empty? || children.all? { |c| c.is_a?(CORE::TextContent) || c.is_a?(CORE::InlineElement) }
            append(result, 'p', paragraph(node, "#{path}/p", authored: false))
          else
            children.each_with_index { |c, i| block(result, c, "#{path}/#{i}") }
          end
          append(parent, tag, result)
        end

        def definition_list_block(parent, node, path)
          list = C::Lists::DefinitionList.new(id: id(node, path))
          Array(node.items).each_with_index do |item, i|
            terms = Array(item.terms)
            terms = [item.term] if terms.empty?
            terms.each_with_index do |term, j|
              dt = C::Lists::DtElement.new(content: [term], id: j.zero? ? item.id : nil)
              append(list, 'dt', dt)
            end
            dd = C::Lists::DdElement.new
            Array(item.definitions).each_with_index do |text, j|
              append(dd, 'p', paragraph(CORE::ParagraphBlock.new(content: text), "#{path}/#{i}/#{j}"))
            end
            block(dd, item.nested, "#{path}/#{i}/nested") if item.nested
            Array(item.attached_children).each_with_index { |child, j| block(dd, child, "#{path}/#{i}/attached/#{j}") }
            append(list, 'dd', dd)
          end
          append(parent, 'dl', list)
        end

        def list_block(parent, node, path)
          ordered = node.marker_type == 'ordered'
          unsupported(node, path, "list type #{node.marker_type}") unless %w[ordered unordered].include?(node.marker_type)
          list = (ordered ? C::Lists::OrderedList : C::Lists::UnorderedList).new(id: id(node, path))
          list.start = node.start.to_s if ordered && node.start
          Array(node.items).each_with_index do |item, i|
            at = "#{path}/items/#{i}"
            li = C::Lists::ListItem.new(id: id(item, at))
            append(li, 'p', paragraph(item, "#{at}/p", authored: false))
            block(li, item.nested_list, "#{at}/nested") if item.nested_list
            append(list, 'li', li)
          end
          append(parent, ordered ? 'ol' : 'ul', list)
        end

        def image_block(parent, node, path)
          unsupported(node, path, 'linked, floating or styled image') if node.link || node.float || node.role
          image = C::IdElements::Image.new(source: node.src, alt: node.alt, width: node.width, height: node.height)
          figure = C::AncillaryBlocks::FigureBlock.new(id: id(node, path), image: image)
          figure.name = C::Inline::NameWithIdElement.new(text: node.caption || node.title) if node.caption || node.title
          append(parent, 'figure', figure)
        end

        def sourcecode_block(parent, node, path)
          unsupported(node, path, 'source callouts') unless Array(node.callouts).empty?
          text = node.content || Array(node.lines).join("\n")
          code = C::AncillaryBlocks::SourcecodeBlock.new(id: id(node, path), lang: node.language, content: text)
          code.name = C::Inline::NameWithIdElement.new(text: node.title) if node.title
          append(parent, 'sourcecode', code)
        end

        def note_block(parent, node, path)
          unsupported(node, path, "annotation #{node.annotation_type}") unless node.annotation_type.to_s.downcase == 'note'
          note = C::Blocks::NoteBlock.new(id: id(node, path))
          note.name = [C::Inline::NameWithIdElement.new(text: node.title)] if node.title
          append(note, 'p', paragraph(node, "#{path}/p", authored: false))
          append(parent, 'note', note)
        end
      end
    end
  end
end
