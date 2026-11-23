# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Quotation < Base
            def to_adoc(model, _options = {})
              _content = serialize_content(model.content)
              "#{_content[/^\s*/]}\"#{_content.strip}\"#{_content[/(?<!\s)\s*+$/]}"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Inline::Quotation, Inline::Quotation)
      end
    end
  end
end
