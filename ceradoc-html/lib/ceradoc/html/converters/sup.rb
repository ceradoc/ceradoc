# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Sup < Base
        INSTANCE = new
        include PositionalFormatting

        private

        def element_class
          Ceradoc::CoreModel::SuperscriptElement
        end
      end

      register :sup, Sup::INSTANCE
    end
  end
end
