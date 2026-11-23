# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Inline
        # Autoload inline elements lazily
        autoload :Base, 'coridoc/asciidoc/model/inline/base'
        autoload :Anchor, 'coridoc/asciidoc/model/inline/anchor'
        autoload :AttributeReference, 'coridoc/asciidoc/model/inline/attribute_reference'
        autoload :Bold, 'coridoc/asciidoc/model/inline/bold'
        autoload :Italic, 'coridoc/asciidoc/model/inline/italic'
        autoload :CrossReference, 'coridoc/asciidoc/model/inline/cross_reference'
        autoload :CrossReferenceArg, 'coridoc/asciidoc/model/inline/cross_reference_arg'
        autoload :Monospace, 'coridoc/asciidoc/model/inline/monospace'
        autoload :Link, 'coridoc/asciidoc/model/inline/link'
        autoload :Quotation, 'coridoc/asciidoc/model/inline/quotation'
        autoload :Highlight, 'coridoc/asciidoc/model/inline/highlight'
        autoload :Subscript, 'coridoc/asciidoc/model/inline/subscript'
        autoload :Superscript, 'coridoc/asciidoc/model/inline/superscript'
        autoload :HardLineBreak, 'coridoc/asciidoc/model/inline/hard_line_break'
        autoload :Span, 'coridoc/asciidoc/model/inline/span'
        autoload :Footnote, 'coridoc/asciidoc/model/inline/footnote'
        autoload :Underline, 'coridoc/asciidoc/model/inline/underline'
        autoload :Small, 'coridoc/asciidoc/model/inline/small'
        autoload :Strikethrough, 'coridoc/asciidoc/model/inline/strikethrough'
        autoload :Stem, 'coridoc/asciidoc/model/inline/stem'
        autoload :Passthrough, 'coridoc/asciidoc/model/inline/passthrough'
      end
    end
  end
end
