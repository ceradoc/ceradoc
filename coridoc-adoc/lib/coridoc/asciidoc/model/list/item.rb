# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module List
        # List item element for ordered and unordered AsciiDoc lists.
        #
        # Represents a single item in an ordered or unordered list, which can
        # contain text content, attached blocks (paragraphs, admonitions),
        # and nested lists.
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the list item
        #
        # @!attribute [r] content
        #   @return [Array<Coridoc::AsciiDoc::Model::Base>] Polymorphic content
        #
        # @!attribute [r] marker
        #   @return [String, nil] Custom list marker for this item
        #
        # @!attribute [r] subitem
        #   @return [String, nil] Sub-item text
        #
        # @!attribute [r] line_break
        #   @return [String] Line break character (default: "\n")
        #
        # @!attribute [r] attached
        #   @return [Array<Coridoc::AsciiDoc::Model::Attached>] Attached blocks
        #
        # @!attribute [r] nested
        #   @return [Coridoc::AsciiDoc::Model::List::Nestable, nil] Nested list
        #
        # @example Create a simple list item
        #   item = Coridoc::AsciiDoc::Model::List::Item.new
        #   item.content = [Coridoc::AsciiDoc::Model::TextElement.new("First item")]
        #
        # @example Create a list item with nested list
        #   item = Coridoc::AsciiDoc::Model::List::Item.new
        #   item.nested = Coridoc::AsciiDoc::Model::List::Unordered.new
        #   item.nested.items << Coridoc::AsciiDoc::Model::List::Item.new
        #
        class Item < Coridoc::AsciiDoc::Model::Base
          include Coridoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :content,
                    Coridoc::AsciiDoc::Model::Base,
                    polymorphic: [
                      Coridoc::AsciiDoc::Model::TextElement,
                      Coridoc::AsciiDoc::Model::Section
                    ]
          attribute :marker, :string
          attribute :subitem, :string
          attribute :line_break, :string, default: -> { "\n" }

          attribute :attached,
                    Coridoc::AsciiDoc::Model::Attached,
                    polymorphic: [
                      Coridoc::AsciiDoc::Model::Admonition,
                      Coridoc::AsciiDoc::Model::Paragraph,
                      Coridoc::AsciiDoc::Model::Block::Core
                    ],
                    collection: true,
                    initialize_empty: true

          attribute :nested, Coridoc::AsciiDoc::Model::List::Nestable
        end
      end
    end
  end
end
