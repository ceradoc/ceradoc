# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      # Handles CommentBlock → omitted (comments are not rendered).
      module Comment
        def self.call(_element, *)
          nil
        end
      end
    end
  end
end
