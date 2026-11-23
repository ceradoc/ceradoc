# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      class BlockImage < Coridoc::AsciiDoc::Model::Image::Core
        class AttributeList < Coridoc::AsciiDoc::Model::Image::Core::AttributeList
          extend AttributeList::Matchers

          def named_validators
            super.merge(
              {
                caption: String,
                align: one('left', 'center', 'right'),
                float: one('left', 'right')
              }
            )
          end
        end
      end
    end
  end
end
