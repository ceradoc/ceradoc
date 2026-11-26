# frozen_string_literal: true

module Ceradoc
  module CoreModel
    # Generic inline formatting element
    #
    # Typed subclasses (BoldElement, ItalicElement, etc.) express their
    # format identity via the class hierarchy — the class IS the format type.
    # Generic InlineElement instances use the format_type attribute for typing.
    class InlineElement < Base
      attribute :children, Base, collection: true

      include ChildrenContent

      def self.format_type
        nil
      end

      def self.format_type_class(type)
        FORMAT_TYPE_CLASS_MAP[type] || InlineElement
      end

      def resolve_format_type
        self.class.format_type || format_type
      end

      # Return a duplicate of this element with its content replaced.
      # Used by InlineContent.strip_edges (and other edge-cleanup
      # callers) so that mutations never leak through the public API.
      def with_content(new_content)
        dup.tap { |copy| copy.content = new_content }
      end

      # Polymorphic classification used by LinkRewriter::Visitor. Returns
      # :link / :xref when this node carries a rewrite-able target, nil
      # otherwise. Generic InlineElement instances defer to their
      # resolved format_type; typed subclasses override with a literal.
      # Keeps the visitor free of class-keyed case/when (OCP).
      def link_kind
        case resolve_format_type
        when 'link' then :link
        when 'xref' then :xref
        end
      end

      attribute :format_type, :string
      attribute :content, :string
      attribute :nested_elements, InlineElement, collection: true
      attribute :target, :string
      attribute :stem_type, :string
      # Emphasis marker spelling recorded by formats that know it
      # (AsciiDoc constrained `*x*` vs unconstrained `**x**`). nil =
      # unknown — serializers fall back to flank inference.
      attribute :constraint, :string

      private

      def comparable_attributes
        %i[format_type content nested_elements stem_type constraint]
      end
    end

    # Typed InlineElement subclasses

    class BoldElement < InlineElement
      def self.format_type
        'bold'
      end
    end

    class ItalicElement < InlineElement
      def self.format_type
        'italic'
      end
    end

    class MonospaceElement < InlineElement
      def self.format_type
        'monospace'
      end
    end

    class UnderlineElement < InlineElement
      def self.format_type
        'underline'
      end
    end

    class StrikethroughElement < InlineElement
      def self.format_type
        'strikethrough'
      end
    end

    class SubscriptElement < InlineElement
      def self.format_type
        'subscript'
      end
    end

    class SuperscriptElement < InlineElement
      def self.format_type
        'superscript'
      end
    end

    class HighlightElement < InlineElement
      def self.format_type
        'highlight'
      end
    end

    class LinkElement < InlineElement
      def self.format_type
        'link'
      end

      def link_kind
        :link
      end

      # Flat text carries both the visible label and the target so
      # text-extraction contexts (conformance flatten, docx runs) keep
      # the destination that raw-string paragraphs used to include.
      def flat_text
        "#{content}#{target}"
      end

      # Display text carries the label only — the parsers' `content`
      # attribute records the visible text, never the destination.
      def display_text
        content.to_s
      end
    end

    class CrossReferenceElement < InlineElement
      def self.format_type
        'xref'
      end

      def link_kind
        :xref
      end
    end

    class StemElement < InlineElement
      def self.format_type
        'stem'
      end
    end

    class FootnoteElement < InlineElement
      def self.format_type
        'footnote'
      end
    end

    class HardLineBreakElement < InlineElement
      def self.format_type
        'hard_line_break'
      end
    end

    class TextElement < InlineElement
      def self.format_type
        'text'
      end
    end

    class SpanElement < InlineElement
      def self.format_type
        'span'
      end
    end

    class TermElement < InlineElement
      def self.format_type
        'term'
      end
    end

    class LineBreakElement < InlineElement
      def self.format_type
        'line_break'
      end
    end

    # Wire-name table: bidirectional string ↔ class index. Single source
    # of truth for serialization names and runtime dispatch. Reopened
    # onto InlineElement so the subclasses above are defined first.
    class InlineElement
      FORMAT_TYPE_CLASS_MAP = {
        'bold' => BoldElement,
        'italic' => ItalicElement,
        'monospace' => MonospaceElement,
        'underline' => UnderlineElement,
        'strikethrough' => StrikethroughElement,
        'subscript' => SubscriptElement,
        'superscript' => SuperscriptElement,
        'highlight' => HighlightElement,
        'link' => LinkElement,
        'xref' => CrossReferenceElement,
        'stem' => StemElement,
        'footnote' => FootnoteElement,
        'hard_line_break' => HardLineBreakElement,
        'text' => TextElement,
        'span' => SpanElement,
        'term' => TermElement,
        'line_break' => LineBreakElement
      }.freeze

      FORMAT_TYPES = FORMAT_TYPE_CLASS_MAP.keys.freeze
    end
  end
end
