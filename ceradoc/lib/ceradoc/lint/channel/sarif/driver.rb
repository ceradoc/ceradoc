# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # The analysis driver: ceradoc plus its deduplicated rules
        # (#379). A lutaml model — the JSON mapping, loading and
        # equality are generated from this declaration; no
        # hand-rolled to_h, ever.
        class Driver < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :rules, 'Ceradoc::Lint::Channel::Sarif::Rule',
                    collection: true, default: -> { [] }

          json do
            map :name, to: :name
            map :rules, to: :rules, render_empty: :as_empty
          end
        end
      end
    end
  end
end
