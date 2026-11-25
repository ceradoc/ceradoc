# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Namespace for all AsciiDoc list types and their items.
      #
      # List Architecture:
      #   - List::Base - Universal list attributes (id, attrs)
      #   - List::Nestable - Marker class for lists nestable inside Item
      #   - List::Core - Ordered/unordered list base (marker, prefix, ol_count)
      #   - List::Ordered - Numbered lists (1., 2., 3., etc.)
      #   - List::Unordered - Bulleted lists (*, **, etc.)
      #   - List::Definition - Labeled/definition lists (term:: definition)
      #   - List::Item - Item for ordered/unordered lists
      #   - List::DefinitionItem - Item for definition lists
      #
      module List
        # Autoload list types lazily
        autoload :Base, 'ceradoc/asciidoc/model/list/base'
        autoload :Core, 'ceradoc/asciidoc/model/list/core'
        autoload :Nestable, 'ceradoc/asciidoc/model/list/nestable'
        autoload :Ordered, 'ceradoc/asciidoc/model/list/ordered'
        autoload :Unordered, 'ceradoc/asciidoc/model/list/unordered'
        autoload :Definition, 'ceradoc/asciidoc/model/list/definition'
        autoload :Item, 'ceradoc/asciidoc/model/list/item'
        autoload :DefinitionItem, 'ceradoc/asciidoc/model/list/definition_item'
      end
    end
  end
end
