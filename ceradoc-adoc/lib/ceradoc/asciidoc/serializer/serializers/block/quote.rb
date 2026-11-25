# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class Quote < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Block::Quote, Block::Quote)
      end
    end
  end
end
