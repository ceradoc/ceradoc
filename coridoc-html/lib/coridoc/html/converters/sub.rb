# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Sub < Base
        INSTANCE = new
        include PositionalFormatting

        private

        def element_class
          Coridoc::CoreModel::SubscriptElement
        end
      end

      register :sub, Sub::INSTANCE
    end
  end
end
