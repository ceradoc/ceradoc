# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # Where a finding's file lives (#379). A lutaml model — the
        # JSON mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class ArtifactLocation < Lutaml::Model::Serializable
          attribute :uri, :string

          json do
            map :uri, to: :uri
          end
        end
      end
    end
  end
end
