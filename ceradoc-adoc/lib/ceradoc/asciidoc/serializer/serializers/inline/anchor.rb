# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Anchor < Base
            def to_adoc(model, _options = {})
              "[[#{model.id}]]"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Inline::Anchor, Inline::Anchor)
      end
    end
  end
end
