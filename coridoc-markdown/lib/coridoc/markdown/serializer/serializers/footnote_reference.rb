# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class FootnoteReference < ElementSerializer
          handles_type ::Coridoc::Markdown::FootnoteReference

          def call(element, _ctx)
            "[^#{element.id}]"
          end
        end
      end
    end
  end
end
