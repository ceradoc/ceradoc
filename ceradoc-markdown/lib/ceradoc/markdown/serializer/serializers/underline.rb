# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class Underline < ElementSerializer
          handles_type ::Ceradoc::Markdown::Underline

          def call(element, _ctx)
            "<u>#{element.text}</u>"
          end
        end
      end
    end
  end
end
