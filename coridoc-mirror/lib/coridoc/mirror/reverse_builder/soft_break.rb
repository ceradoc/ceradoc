# frozen_string_literal: true

module Coridoc
  module Mirror
    module ReverseBuilder
      class SoftBreak < Base
        def build(_node)
          CoreModel::LineBreakElement.new
        end
      end
    end
  end
end
