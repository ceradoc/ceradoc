# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Lsp
        # One finding in LSP vocabulary (#379): range, severity
        # number, code, source and message. A lutaml model — the JSON
        # mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Diagnostic < Lutaml::Model::Serializable
          attribute :range, 'Ceradoc::Lint::Channel::Lsp::PositionRange'
          attribute :severity, :integer
          attribute :code, :string
          attribute :source, :string
          attribute :message, :string

          json do
            map :range, to: :range
            map :severity, to: :severity
            map :code, to: :code
            map :source, to: :source
            map :message, to: :message
          end
        end
      end
    end
  end
end
