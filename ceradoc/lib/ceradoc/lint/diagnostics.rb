# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    # A run's findings as ONE document: the serialization unit every
    # channel writes and parses back (#378). A lutaml model — the JSON
    # mapping, loading and equality are generated from this
    # declaration; no hand-rolled to_h, ever.
    class Diagnostics < Lutaml::Model::Serializable
      attribute :diagnostics, 'Ceradoc::Lint::Diagnostic', collection: true,
                                                           default: -> { [] }

      # The collection is always on the wire — an empty run emits
      # {"diagnostics": []}, never a bare {} — so every document,
      # including the empty one, parses back into Diagnostics.
      json do
        map :diagnostics, to: :diagnostics, render_empty: :as_empty
      end
    end
  end
end
