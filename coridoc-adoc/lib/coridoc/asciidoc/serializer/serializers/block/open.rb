# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Open < Core
            def to_adoc(model, _options = {})
              @model = model
              "\n\n#{gen_anchor}#{gen_attributes}#{gen_delimiter}\n" <<
                gen_lines << "\n#{gen_delimiter}\n\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Block::Open, Block::Open)
      end
    end
  end
end
