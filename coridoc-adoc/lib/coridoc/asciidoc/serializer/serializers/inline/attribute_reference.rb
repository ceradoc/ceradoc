# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class AttributeReference < Base
            def to_adoc(model, _options = {})
              "{#{model.name}}"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::AttributeReference, Inline::AttributeReference)
      end
    end
  end
end
