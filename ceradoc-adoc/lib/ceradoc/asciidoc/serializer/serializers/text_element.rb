# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Serializer for TextElement models
        class TextElement < Base
          def to_adoc(model, _options = {})
            result = ''
            result += "[[#{model.id}]] " if model.id
            content = serialize_content(model.content)
            # Delimiter escaping is for PLAIN text only (#92). When the
            # content array carried inline models, the composed string
            # already contains serialized markup (`*bold*`, `` `code` ``)
            # whose delimiters must survive verbatim — each inner element
            # escaped its own plain text (#376).
            content = Ceradoc::Util::AsciiDoc.escape_text_delimiters(content) if plain_content?(model.content)
            result += content
            result += model.line_break.to_s
            result
          end

          private

          def plain_content?(content)
            case content
            when String then true
            when Array then content.all?(String)
            else false
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Ceradoc::AsciiDoc::Model::TextElement, Serializers::TextElement)
    end
  end
end
