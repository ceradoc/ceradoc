# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class Code < ElementSerializer
          handles_type ::Ceradoc::Markdown::Code

          def call(element, _ctx)
            "`#{element.text}`"
          end
        end
      end
    end
  end
end
