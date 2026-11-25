# frozen_string_literal: true

require 'cgi'

module Ceradoc
  module Markdown
    module Transform
      module InlineTransformer
        class << self
          def transform_inline(element)
            case element.resolve_format_type
            when 'bold'
              Ceradoc::Markdown::Strong.new(text: element.content.to_s)
            when 'italic'
              Ceradoc::Markdown::Emphasis.new(text: element.content.to_s)
            when 'monospace'
              Ceradoc::Markdown::Code.new(text: element.content.to_s)
            when 'link'
              Ceradoc::Markdown::Link.new(
                text: element.content.to_s,
                url: element.target.to_s
              )
            when 'footnote'
              Ceradoc::Markdown::FootnoteReference.new(id: element.target.to_s)
            when 'stem'
              Ceradoc::Markdown::Math.inline(element.content.to_s)
            when 'highlight'
              Ceradoc::Markdown::Highlight.new(text: element.content.to_s)
            when 'strikethrough'
              Ceradoc::Markdown::Strikethrough.new(text: element.content.to_s)
            when 'subscript'
              Ceradoc::Markdown::Subscript.new(text: element.content.to_s)
            when 'superscript'
              Ceradoc::Markdown::Superscript.new(text: element.content.to_s)
            when 'underline'
              Ceradoc::Markdown::Underline.new(text: element.content.to_s)
            when 'xref'
              Ceradoc::Markdown::CrossReference.new(
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
            Ceradoc::Markdown::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Ceradoc::Markdown::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Ceradoc::Markdown::Abbreviation.new(
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
        FromCoreModel.register(CoreModel::Term, ->(m) { Ceradoc::Markdown::Strong.new(text: m.text.to_s) })
      end
    end
  end
end
