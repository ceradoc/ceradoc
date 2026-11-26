# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Lsp
        # The LSP range: start and end positions (#379). Named
        # PositionRange because Ruby owns the bare Range name. A
        # lutaml model — the JSON mapping, loading and equality are
        # generated from this declaration; no hand-rolled to_h, ever.
        class PositionRange < Lutaml::Model::Serializable
          attribute :start, 'Ceradoc::Lint::Channel::Lsp::Position'
          attribute :end, 'Ceradoc::Lint::Channel::Lsp::Position'

          json do
            map :start, to: :start
            map :end, to: :end
          end
        end
      end
    end
  end
end
