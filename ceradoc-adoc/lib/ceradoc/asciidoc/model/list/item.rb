# frozen_string_literal: true

module Ceradoc
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
        #   @return [Array<Ceradoc::AsciiDoc::Model::Base>] Polymorphic content
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
        #   @return [Array<Ceradoc::AsciiDoc::Model::Attached>] Attached blocks
        #
        # @!attribute [r] nested
        #   @return [Ceradoc::AsciiDoc::Model::List::Nestable, nil] Nested list
        #
        # @example Create a simple list item
        #   item = Ceradoc::AsciiDoc::Model::List::Item.new
        #   item.content = [Ceradoc::AsciiDoc::Model::TextElement.new("First item")]
        #
        # @example Create a list item with nested list
        #   item = Ceradoc::AsciiDoc::Model::List::Item.new
        #   item.nested = Ceradoc::AsciiDoc::Model::List::Unordered.new
        #   item.nested.items << Ceradoc::AsciiDoc::Model::List::Item.new
        #
        class Item < Ceradoc::AsciiDoc::Model::Base
          include Ceradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :content,
                    Ceradoc::AsciiDoc::Model::Base,
                    polymorphic: [
                      Ceradoc::AsciiDoc::Model::TextElement,
                      Ceradoc::AsciiDoc::Model::Section
                    ]
          attribute :marker, :string
          attribute :subitem, :string
          attribute :line_break, :string, default: -> { "\n" }

          attribute :attached,
                    Ceradoc::AsciiDoc::Model::Attached,
                    polymorphic: [
                      Ceradoc::AsciiDoc::Model::Admonition,
                      Ceradoc::AsciiDoc::Model::Paragraph,
                      Ceradoc::AsciiDoc::Model::Block::Core
                    ],
                    collection: true,
                    initialize_empty: true

          attribute :nested, Ceradoc::AsciiDoc::Model::List::Nestable
        end
      end
    end
  end
end
