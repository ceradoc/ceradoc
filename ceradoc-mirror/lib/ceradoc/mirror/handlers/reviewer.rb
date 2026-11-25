# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      # Handles ReviewerBlock → omitted (reviewer notes are not rendered).
      module Reviewer
        def self.call(_element, *)
          nil
        end
      end
    end
  end
end
