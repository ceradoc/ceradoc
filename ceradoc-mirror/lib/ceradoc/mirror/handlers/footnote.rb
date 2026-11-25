# frozen_string_literal: true

module Ceradoc
  module Mirror
    module Handlers
      # Handles Footnote and FootnoteReference.
      module Footnote
        def self.call(element, context:)
          context.register_footnote(element)
        end

        def self.reference(element, context:)
          context.resolve_footnote_reference(element)
        end
      end
    end
  end
end
