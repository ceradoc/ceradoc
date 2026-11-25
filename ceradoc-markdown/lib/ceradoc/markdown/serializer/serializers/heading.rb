# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class Heading < ElementSerializer
          handles_type ::Ceradoc::Markdown::Heading

          def call(element, _ctx)
            "#{'#' * element.level} #{element.text}"
          end
        end
      end
    end
  end
end
