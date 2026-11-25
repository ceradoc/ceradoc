# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class HorizontalRule < Base
        def build(_node)
          CoreModel::HorizontalRuleBlock.new
        end
      end
    end
  end
end
