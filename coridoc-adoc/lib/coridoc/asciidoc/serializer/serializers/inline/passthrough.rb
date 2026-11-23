# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for the inline passthrough (`+++raw content+++`).
          # Wraps the raw payload in triple-plus delimiters so downstream
          # consumers know to skip inline substitution.
          class Passthrough < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              return '' if content.empty?

              "+++#{content}+++"
            end
          end
        end

        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Passthrough, Inline::Passthrough)
      end
    end
  end
end
