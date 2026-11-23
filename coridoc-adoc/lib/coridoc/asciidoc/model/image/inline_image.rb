# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Image
        class InlineImage < Coridoc::AsciiDoc::Model::Image::Core
          def inline?
            true
          end

          attribute :colons, :string, default: -> { ':' }

          # Inline images use the 2nd positional slot for the role, per
          # Asciidoctor: `image:target[alt, role, width=N, ...]`.
          # @return [Array<Symbol>]
          def self.promoted_positional
            %i[alt role]
          end
        end
      end
    end
  end
end
