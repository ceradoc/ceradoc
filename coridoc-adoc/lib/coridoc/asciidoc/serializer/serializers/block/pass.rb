# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Pass < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Block::Pass, Block::Pass)
      end
    end
  end
end
