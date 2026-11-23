# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Small < Base
            def to_adoc(model, _options = {})
              "[.small]##{model.text}#"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Small, Inline::Small)
      end
    end
  end
end
