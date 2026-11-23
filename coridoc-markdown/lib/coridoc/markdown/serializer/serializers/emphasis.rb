# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Emphasis < ElementSerializer
          handles_type ::Coridoc::Markdown::Emphasis

          def call(element, _ctx)
            "*#{element.text}*"
          end
        end
      end
    end
  end
end
