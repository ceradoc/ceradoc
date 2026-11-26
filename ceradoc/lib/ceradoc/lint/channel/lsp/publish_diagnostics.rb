# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Lsp
        # The publishDiagnostics document (#379): a bare JSON array of
        # per-uri entries, one per document. A lutaml Collection — the
        # unwrapped-array mapping, loading and equality are generated
        # from this declaration; no hand-rolled to_h, ever.
        class PublishDiagnostics < Lutaml::Model::Collection
          instances :items, 'Ceradoc::Lint::Channel::Lsp::FileDiagnostics'

          json do
            map :items, to: :items, render_empty: :as_empty
          end
        end
      end
    end
  end
end
