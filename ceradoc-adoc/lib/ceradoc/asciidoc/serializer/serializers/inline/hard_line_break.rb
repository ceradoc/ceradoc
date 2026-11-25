# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class HardLineBreak < Base
            def to_adoc(_model, _options = {})
              " +\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Inline::HardLineBreak, Inline::HardLineBreak)
      end
    end
  end
end
