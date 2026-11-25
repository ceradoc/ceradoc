# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      class BlockImage < Ceradoc::AsciiDoc::Model::Image::Core
        class AttributeList < Ceradoc::AsciiDoc::Model::Image::Core::AttributeList
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
