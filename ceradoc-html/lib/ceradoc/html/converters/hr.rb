# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Hr < Base
        INSTANCE = new

        def to_ceradoc(_node, _state = {})
          Ceradoc::CoreModel::HorizontalRuleBlock.new
        end
      end

      register :hr, Hr::INSTANCE
    end
  end
end
