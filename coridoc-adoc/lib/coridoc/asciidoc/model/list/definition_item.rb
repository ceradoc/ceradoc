# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module List
        # Definition list item for AsciiDoc definition/labeled lists.
        #
        # A DefinitionItem contains one or more terms and their associated
        # definitions. In AsciiDoc, this maps to the labeled list syntax:
        #
        #   Term 1:: Definition 1
        #   Term 2::: Definition 2 (deeper level)
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the definition item
        #
        # @!attribute [r] terms
        #   @return [Array<Term>] The terms being defined (can have multiple)
        #
        # @!attribute [r] contents
        #   @return [Array<TextElement>] The definitions/contents for the terms
        #
        # @example Create a definition list item
        #   item = Coridoc::AsciiDoc::Model::List::DefinitionItem.new
        #   item.terms << Coridoc::AsciiDoc::Model::Term.new(term: "API")
        #   item.contents << Coridoc::AsciiDoc::Model::TextElement.new("Application Programming Interface")
        #
        class DefinitionItem < Coridoc::AsciiDoc::Model::Base
          include Coridoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :terms, Coridoc::AsciiDoc::Model::Term, collection: true
          attribute :contents, Coridoc::AsciiDoc::Model::TextElement, collection: true
          attribute :delimiter, :string, default: -> { '::' }
          # `+`-continuation blocks attached to this dd (paragraphs,
          # admonitions, delimited blocks). Same shape as Model::List::Item's
          # attached collection — populated by the parser when an AsciiDoc
          # `+` line follows the dd.
          attribute :attached,
                    Coridoc::AsciiDoc::Model::Attached,
                    polymorphic: [
                      Coridoc::AsciiDoc::Model::Admonition,
                      Coridoc::AsciiDoc::Model::Paragraph,
                      Coridoc::AsciiDoc::Model::Block::Core
                    ],
                    collection: true,
                    initialize_empty: true
          attribute :nested,
                    Coridoc::AsciiDoc::Model::Base,
                    polymorphic: [Coridoc::AsciiDoc::Model::List::Definition],
                    collection: true,
                    initialize_empty: true

          def to_adoc(delimiter: '')
            Coridoc::AsciiDoc::Serializer.serialize(self, delimiter: delimiter)
          end
        end
      end
    end
  end
end
