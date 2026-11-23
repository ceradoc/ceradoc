# frozen_string_literal: true

module Coridoc
  module Mirror
    module ReverseBuilder
      class HardBreak < Base
        def build(_node)
          CoreModel::HardLineBreakElement.new(content: '')
        end
      end
    end
  end
end
