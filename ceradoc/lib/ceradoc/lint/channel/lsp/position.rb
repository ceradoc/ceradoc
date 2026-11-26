# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Lsp
        # A zero-based text position in the LSP vocabulary (#379). A
        # lutaml model — the JSON mapping, loading and equality are
        # generated from this declaration; no hand-rolled to_h, ever.
        class Position < Lutaml::Model::Serializable
          attribute :line, :integer
          attribute :character, :integer

          json do
            map :line, to: :line
            map :character, to: :character
          end
        end
      end
    end
  end
end
