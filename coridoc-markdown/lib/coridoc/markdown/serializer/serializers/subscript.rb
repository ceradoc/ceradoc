# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Subscript < ElementSerializer
          handles_type ::Coridoc::Markdown::Subscript

          def call(element, _ctx)
            "<sub>#{element.text}</sub>"
          end
        end
      end
    end
  end
end
