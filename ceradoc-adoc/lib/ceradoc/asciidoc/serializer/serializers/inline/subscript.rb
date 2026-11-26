# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Subscript inline formatting
          class Subscript < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Ceradoc::Util::AsciiDoc.escape_characters(
                content,
                escape_chars: %w[~]
              )

              return '' if content.empty?

              "~#{content}~"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Inline::Subscript, Inline::Subscript)
      end
    end
  end
end
