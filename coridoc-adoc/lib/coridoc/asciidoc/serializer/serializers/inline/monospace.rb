# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Monospace inline formatting
          class Monospace < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coridoc::Util::AsciiDoc.escape_characters(content, escape_chars: ['`'])

              return '' if content.empty?

              model.unconstrained ? "``#{content}``" : "`#{content}`"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Monospace, Inline::Monospace)
      end
    end
  end
end
