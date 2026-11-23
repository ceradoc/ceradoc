# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Heading < ElementSerializer
          handles_type ::Coridoc::Markdown::Heading

          def call(element, _ctx)
            "#{'#' * element.level} #{element.text}"
          end
        end
      end
    end
  end
end
