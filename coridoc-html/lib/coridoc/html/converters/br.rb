# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Br < Base
        INSTANCE = new

        def to_coridoc(_node, _state = {})
          Coridoc::CoreModel::LineBreakElement.new
        end
      end

      register :br, Br::INSTANCE
    end
  end
end
