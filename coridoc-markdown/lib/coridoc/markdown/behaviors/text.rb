# frozen_string_literal: true

module Coridoc
  module Markdown
    module Behaviors
      # Hand-written behavior for Text.
      module Text
        def to_s
          content
        end
      end
    end
  end
end
