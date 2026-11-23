# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Italic inline formatting
          class Italic < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coridoc::Util::AsciiDoc.escape_characters(content, escape_chars: ['_'])

              return '' if content.empty?

              model.unconstrained ? "__#{content}__" : "_#{content}_"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Italic, Inline::Italic)
      end
    end
  end
end
