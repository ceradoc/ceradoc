# frozen_string_literal: true

require_relative '../element_serializer'
require_relative '../strategies/definition_list/registry'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class DefinitionList < ElementSerializer
          handles_type ::Ceradoc::Markdown::DefinitionList

          def call(element, ctx)
            Strategies::DefinitionList::Registry.render(element, ctx)
          end
        end
      end
    end
  end
end
