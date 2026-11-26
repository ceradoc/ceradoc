# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # The rendered finding text (#379). A lutaml model — the JSON
        # mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Message < Lutaml::Model::Serializable
          attribute :text, :string

          json do
            map :text, to: :text
          end
        end
      end
    end
  end
end
