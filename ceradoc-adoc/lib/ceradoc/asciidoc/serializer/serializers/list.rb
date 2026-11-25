# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload list serializers
        module List
          autoload :Core, 'ceradoc/asciidoc/serializer/serializers/list/core'
          autoload :Definition, 'ceradoc/asciidoc/serializer/serializers/list/definition'
          autoload :DefinitionItem, 'ceradoc/asciidoc/serializer/serializers/list/definition_item'
          autoload :Item, 'ceradoc/asciidoc/serializer/serializers/list/item'
          autoload :Ordered, 'ceradoc/asciidoc/serializer/serializers/list/ordered'
          autoload :Unordered, 'ceradoc/asciidoc/serializer/serializers/list/unordered'
        end
      end
    end
  end
end
