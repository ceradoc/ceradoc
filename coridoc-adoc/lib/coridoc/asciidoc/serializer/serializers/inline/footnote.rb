# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Footnote < Base
            def to_adoc(model, _options = {})
              if model.id
                "footnote:#{model.id}[#{model.text}]"
              else
                "footnote:[#{model.text}]"
              end
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Footnote, Inline::Footnote)
      end
    end
  end
end
