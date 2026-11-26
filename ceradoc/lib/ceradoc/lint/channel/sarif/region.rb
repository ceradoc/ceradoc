# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # A one-based source region (#379). A lutaml model — the JSON
        # mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Region < Lutaml::Model::Serializable
          attribute :start_line, :integer

          json do
            map :startLine, to: :start_line
          end
        end
      end
    end
  end
end
