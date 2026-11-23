# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Footnote < ElementSerializer
          handles_type ::Coridoc::Markdown::Footnote

          def call(element, _ctx)
            content = element.content.to_s
            "[^#{element.id}]: #{content}"
          end
        end
      end
    end
  end
end
