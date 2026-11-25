# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class ReviewerComment < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::Block::ReviewerComment, Block::ReviewerComment)
      end
    end
  end
end
