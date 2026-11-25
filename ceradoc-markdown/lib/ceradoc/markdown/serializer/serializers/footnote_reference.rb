# frozen_string_literal: true

require_relative '../element_serializer'

module Ceradoc
  module Markdown
    class Serializer
      module Serializers
        class FootnoteReference < ElementSerializer
          handles_type ::Ceradoc::Markdown::FootnoteReference

          def call(element, _ctx)
            "[^#{element.id}]"
          end
        end
      end
    end
  end
end
