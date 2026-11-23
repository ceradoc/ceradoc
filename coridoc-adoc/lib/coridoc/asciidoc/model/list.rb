# frozen_string_literal: true

module Coridoc
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
        autoload :Base, 'coridoc/asciidoc/model/list/base'
        autoload :Core, 'coridoc/asciidoc/model/list/core'
        autoload :Nestable, 'coridoc/asciidoc/model/list/nestable'
        autoload :Ordered, 'coridoc/asciidoc/model/list/ordered'
        autoload :Unordered, 'coridoc/asciidoc/model/list/unordered'
        autoload :Definition, 'coridoc/asciidoc/model/list/definition'
        autoload :Item, 'coridoc/asciidoc/model/list/item'
        autoload :DefinitionItem, 'coridoc/asciidoc/model/list/definition_item'
      end
    end
  end
end
