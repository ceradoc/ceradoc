# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Extension < ElementSerializer
          handles_type ::Coridoc::Markdown::Extension

          def call(element, _ctx)
            element.extension_syntax
          end
        end
      end
    end
  end
end
