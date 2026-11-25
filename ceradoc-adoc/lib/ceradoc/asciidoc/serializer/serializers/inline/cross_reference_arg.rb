# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class CrossReferenceArg < Base
            def to_adoc(model, _options = {})
              [model.key, model.delimiter, model.value].join
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Inline::CrossReferenceArg, Inline::CrossReferenceArg)
      end
    end
  end
end
