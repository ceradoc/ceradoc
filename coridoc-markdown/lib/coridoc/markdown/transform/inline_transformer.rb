# frozen_string_literal: true

require 'cgi'

module Coridoc
  module Markdown
    module Transform
      module InlineTransformer
        class << self
          def transform_inline(element)
            case element.resolve_format_type
            when 'bold'
              Coridoc::Markdown::Strong.new(text: element.content.to_s)
            when 'italic'
              Coridoc::Markdown::Emphasis.new(text: element.content.to_s)
            when 'monospace'
              Coridoc::Markdown::Code.new(text: element.content.to_s)
            when 'link'
              Coridoc::Markdown::Link.new(
                text: element.content.to_s,
                url: element.target.to_s
              )
            when 'footnote'
              Coridoc::Markdown::FootnoteReference.new(id: element.target.to_s)
            when 'stem'
              Coridoc::Markdown::Math.inline(element.content.to_s)
            when 'highlight'
              Coridoc::Markdown::Highlight.new(text: element.content.to_s)
            when 'strikethrough'
              Coridoc::Markdown::Strikethrough.new(text: element.content.to_s)
            when 'subscript'
              Coridoc::Markdown::Subscript.new(text: element.content.to_s)
            when 'superscript'
              Coridoc::Markdown::Superscript.new(text: element.content.to_s)
            when 'underline'
              Coridoc::Markdown::Underline.new(text: element.content.to_s)
            when 'xref'
              Coridoc::Markdown::CrossReference.new(
                text: element.content.to_s,
                target: element.target.to_s
              )
            when 'raw_inline'
              CGI.escapeHTML(element.content.to_s)
            else
              element.content.to_s
            end
          end

          def transform_footnote(fn)
            Coridoc::Markdown::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Coridoc::Markdown::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Coridoc::Markdown::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end
        end

        FromCoreModel.register(CoreModel::InlineElement, method(:transform_inline))
        FromCoreModel.register(CoreModel::Footnote, method(:transform_footnote))
        FromCoreModel.register(CoreModel::FootnoteReference, method(:transform_footnote_reference))
        FromCoreModel.register(CoreModel::Abbreviation, method(:transform_abbreviation))
        FromCoreModel.register(CoreModel::TextContent, lambda(&:text))
        FromCoreModel.register(CoreModel::Term, ->(m) { Coridoc::Markdown::Strong.new(text: m.text.to_s) })
      end
    end
  end
end
