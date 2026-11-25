# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Br < Base
        INSTANCE = new

        def to_ceradoc(_node, _state = {})
          Ceradoc::CoreModel::LineBreakElement.new
        end
      end

      register :br, Br::INSTANCE
    end
  end
end
