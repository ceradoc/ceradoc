# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload inline serializers
        module Inline
          autoload :Anchor, 'coridoc/asciidoc/serializer/serializers/inline/anchor'
          autoload :AttributeReference, 'coridoc/asciidoc/serializer/serializers/inline/attribute_reference'
          autoload :Bold, 'coridoc/asciidoc/serializer/serializers/inline/bold'
          autoload :CrossReference, 'coridoc/asciidoc/serializer/serializers/inline/cross_reference'
          autoload :CrossReferenceArg, 'coridoc/asciidoc/serializer/serializers/inline/cross_reference_arg'
          autoload :Footnote, 'coridoc/asciidoc/serializer/serializers/inline/footnote'
          autoload :HardLineBreak, 'coridoc/asciidoc/serializer/serializers/inline/hard_line_break'
          autoload :Highlight, 'coridoc/asciidoc/serializer/serializers/inline/highlight'
          autoload :Italic, 'coridoc/asciidoc/serializer/serializers/inline/italic'
          autoload :Link, 'coridoc/asciidoc/serializer/serializers/inline/link'
          autoload :Monospace, 'coridoc/asciidoc/serializer/serializers/inline/monospace'
          autoload :Passthrough, 'coridoc/asciidoc/serializer/serializers/inline/passthrough'
          autoload :Quotation, 'coridoc/asciidoc/serializer/serializers/inline/quotation'
          autoload :Small, 'coridoc/asciidoc/serializer/serializers/inline/small'
          autoload :Span, 'coridoc/asciidoc/serializer/serializers/inline/span'
          autoload :Stem, 'coridoc/asciidoc/serializer/serializers/inline/stem'
          autoload :Strikethrough, 'coridoc/asciidoc/serializer/serializers/inline/strikethrough'
          autoload :Subscript, 'coridoc/asciidoc/serializer/serializers/inline/subscript'
          autoload :Superscript, 'coridoc/asciidoc/serializer/serializers/inline/superscript'
          autoload :Underline, 'coridoc/asciidoc/serializer/serializers/inline/underline'
        end
      end
    end
  end
end
