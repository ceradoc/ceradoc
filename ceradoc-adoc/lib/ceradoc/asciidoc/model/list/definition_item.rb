# frozen_string_literal: true

module Ceradoc
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
        #   item = Ceradoc::AsciiDoc::Model::List::DefinitionItem.new
        #   item.terms << Ceradoc::AsciiDoc::Model::Term.new(term: "API")
        #   item.contents << Ceradoc::AsciiDoc::Model::TextElement.new("Application Programming Interface")
        #
        class DefinitionItem < Ceradoc::AsciiDoc::Model::Base
          include Ceradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :terms, Ceradoc::AsciiDoc::Model::Term, collection: true
          attribute :contents, Ceradoc::AsciiDoc::Model::TextElement, collection: true
          attribute :delimiter, :string, default: -> { '::' }
          # `+`-continuation blocks attached to this dd (paragraphs,
          # admonitions, delimited blocks). Same shape as Model::List::Item's
          # attached collection — populated by the parser when an AsciiDoc
          # `+` line follows the dd.
          attribute :attached,
                    Ceradoc::AsciiDoc::Model::Attached,
                    polymorphic: [
                      Ceradoc::AsciiDoc::Model::Admonition,
                      Ceradoc::AsciiDoc::Model::Paragraph,
                      Ceradoc::AsciiDoc::Model::Block::Core
                    ],
                    collection: true,
                    initialize_empty: true
          attribute :nested,
                    Ceradoc::AsciiDoc::Model::Base,
                    polymorphic: [Ceradoc::AsciiDoc::Model::List::Definition],
                    collection: true,
                    initialize_empty: true

          def to_adoc(delimiter: '')
            Ceradoc::AsciiDoc::Serializer.serialize(self, delimiter: delimiter)
          end
        end
      end
    end
  end
end
