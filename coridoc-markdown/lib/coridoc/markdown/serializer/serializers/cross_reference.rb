# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class CrossReference < ElementSerializer
          handles_type ::Coridoc::Markdown::CrossReference

          def call(element, _ctx)
            "[#{element.text}](##{element.target})"
          end
        end
      end
    end
  end
end
