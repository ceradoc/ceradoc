# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Sub < Base
        INSTANCE = new
        include PositionalFormatting

        private

        def element_class
          Ceradoc::CoreModel::SubscriptElement
        end
      end

      register :sub, Sub::INSTANCE
    end
  end
end
