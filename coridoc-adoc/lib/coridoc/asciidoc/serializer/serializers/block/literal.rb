# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Literal < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Block::Literal, Block::Literal)
      end
    end
  end
end
