# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class Text < ElementSerializer
          handles_type ::Ceradoc::Markdown::Text

          def call(element, _ctx)
            element.content.to_s
          end
        end
      end
    end
  end
end
