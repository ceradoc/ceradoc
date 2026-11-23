# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class ReviewerComment < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coridoc::AsciiDoc::Model::Block::ReviewerComment, Block::ReviewerComment)
      end
    end
  end
end
