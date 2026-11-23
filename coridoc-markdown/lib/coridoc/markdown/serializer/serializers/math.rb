# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Math < ElementSerializer
          handles_type ::Coridoc::Markdown::Math

          def call(element, _ctx)
            if element.inline?
              "$$#{element.content}$$"
            else
              "$$\n#{element.content}\n$$"
            end
          end
        end
      end
    end
  end
end
