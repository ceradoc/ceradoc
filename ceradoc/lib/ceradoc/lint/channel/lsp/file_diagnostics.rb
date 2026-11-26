# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Lsp
        # The per-document publishDiagnostics entry (#379): one uri
        # and its diagnostics. A lutaml model — the JSON mapping,
        # loading and equality are generated from this declaration;
        # no hand-rolled to_h, ever.
        class FileDiagnostics < Lutaml::Model::Serializable
          attribute :uri, :string
          attribute :diagnostics, 'Ceradoc::Lint::Channel::Lsp::Diagnostic',
                    collection: true, default: -> { [] }

          json do
            map :uri, to: :uri
            map :diagnostics, to: :diagnostics, render_empty: :as_empty
          end
        end
      end
    end
  end
end
