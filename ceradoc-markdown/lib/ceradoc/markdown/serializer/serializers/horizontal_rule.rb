# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class HorizontalRule < ElementSerializer
          handles_type ::Ceradoc::Markdown::HorizontalRule

          def call(element, _ctx)
            element.style || '---'
          end
        end
      end
    end
  end
end
