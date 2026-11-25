# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload inline serializers
        module Inline
          autoload :Anchor, 'ceradoc/asciidoc/serializer/serializers/inline/anchor'
          autoload :AttributeReference, 'ceradoc/asciidoc/serializer/serializers/inline/attribute_reference'
          autoload :Bold, 'ceradoc/asciidoc/serializer/serializers/inline/bold'
          autoload :CrossReference, 'ceradoc/asciidoc/serializer/serializers/inline/cross_reference'
          autoload :CrossReferenceArg, 'ceradoc/asciidoc/serializer/serializers/inline/cross_reference_arg'
          autoload :Footnote, 'ceradoc/asciidoc/serializer/serializers/inline/footnote'
          autoload :HardLineBreak, 'ceradoc/asciidoc/serializer/serializers/inline/hard_line_break'
          autoload :Highlight, 'ceradoc/asciidoc/serializer/serializers/inline/highlight'
          autoload :Italic, 'ceradoc/asciidoc/serializer/serializers/inline/italic'
          autoload :Link, 'ceradoc/asciidoc/serializer/serializers/inline/link'
          autoload :Monospace, 'ceradoc/asciidoc/serializer/serializers/inline/monospace'
          autoload :Passthrough, 'ceradoc/asciidoc/serializer/serializers/inline/passthrough'
          autoload :Quotation, 'ceradoc/asciidoc/serializer/serializers/inline/quotation'
          autoload :Small, 'ceradoc/asciidoc/serializer/serializers/inline/small'
          autoload :Span, 'ceradoc/asciidoc/serializer/serializers/inline/span'
          autoload :Stem, 'ceradoc/asciidoc/serializer/serializers/inline/stem'
          autoload :Strikethrough, 'ceradoc/asciidoc/serializer/serializers/inline/strikethrough'
          autoload :Subscript, 'ceradoc/asciidoc/serializer/serializers/inline/subscript'
          autoload :Superscript, 'ceradoc/asciidoc/serializer/serializers/inline/superscript'
          autoload :Underline, 'ceradoc/asciidoc/serializer/serializers/inline/underline'
        end
      end
    end
  end
end
