# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Hr < Base
        INSTANCE = new

        def to_coridoc(_node, _state = {})
          Coridoc::CoreModel::HorizontalRuleBlock.new
        end
      end

      register :hr, Hr::INSTANCE
    end
  end
end
