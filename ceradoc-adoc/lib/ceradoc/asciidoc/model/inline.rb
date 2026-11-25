# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Inline
        # Autoload inline elements lazily
        autoload :Base, 'ceradoc/asciidoc/model/inline/base'
        autoload :Anchor, 'ceradoc/asciidoc/model/inline/anchor'
        autoload :AttributeReference, 'ceradoc/asciidoc/model/inline/attribute_reference'
        autoload :Bold, 'ceradoc/asciidoc/model/inline/bold'
        autoload :Italic, 'ceradoc/asciidoc/model/inline/italic'
        autoload :CrossReference, 'ceradoc/asciidoc/model/inline/cross_reference'
        autoload :CrossReferenceArg, 'ceradoc/asciidoc/model/inline/cross_reference_arg'
        autoload :Monospace, 'ceradoc/asciidoc/model/inline/monospace'
        autoload :Link, 'ceradoc/asciidoc/model/inline/link'
        autoload :Quotation, 'ceradoc/asciidoc/model/inline/quotation'
        autoload :Highlight, 'ceradoc/asciidoc/model/inline/highlight'
        autoload :Subscript, 'ceradoc/asciidoc/model/inline/subscript'
        autoload :Superscript, 'ceradoc/asciidoc/model/inline/superscript'
        autoload :HardLineBreak, 'ceradoc/asciidoc/model/inline/hard_line_break'
        autoload :Span, 'ceradoc/asciidoc/model/inline/span'
        autoload :Footnote, 'ceradoc/asciidoc/model/inline/footnote'
        autoload :Underline, 'ceradoc/asciidoc/model/inline/underline'
        autoload :Small, 'ceradoc/asciidoc/model/inline/small'
        autoload :Strikethrough, 'ceradoc/asciidoc/model/inline/strikethrough'
        autoload :Stem, 'ceradoc/asciidoc/model/inline/stem'
        autoload :Passthrough, 'ceradoc/asciidoc/model/inline/passthrough'
      end
    end
  end
end
