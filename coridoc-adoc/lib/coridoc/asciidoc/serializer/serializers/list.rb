# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload list serializers
        module List
          autoload :Core, 'coridoc/asciidoc/serializer/serializers/list/core'
          autoload :Definition, 'coridoc/asciidoc/serializer/serializers/list/definition'
          autoload :DefinitionItem, 'coridoc/asciidoc/serializer/serializers/list/definition_item'
          autoload :Item, 'coridoc/asciidoc/serializer/serializers/list/item'
          autoload :Ordered, 'coridoc/asciidoc/serializer/serializers/list/ordered'
          autoload :Unordered, 'coridoc/asciidoc/serializer/serializers/list/unordered'
        end
      end
    end
  end
end
