# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Inline
        # Hard line break inline element for AsciiDoc documents.
        #
        # Hard line breaks force a line break at a specific point.
        # Rendered as a plus sign at the end of a line: +.
        #
        # @example Create a hard line break
        #   break = Ceradoc::AsciiDoc::Model::Inline::HardLineBreak.new
        #   break.to_adoc # => " +"
        #
        class HardLineBreak < Base
          def inline?
            :hardbreak
          end
        end
      end
    end
  end
end
