# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Highlight inline formatting
          class Highlight < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coridoc::Util::AsciiDoc.escape_characters(content, escape_chars: ['#'])

              return '' if content.empty?

              model.unconstrained ? "###{content}##" : "##{content}#"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Highlight, Inline::Highlight)
      end
    end
  end
end
