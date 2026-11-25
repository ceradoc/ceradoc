# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      # Handles HorizontalRuleBlock → horizontal_rule node.
      module HorizontalRule
        def self.call(_element, *)
          Node::HorizontalRule.new
        end
      end
    end
  end
end
