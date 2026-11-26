# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # The SARIF log: the versioned container of runs (#379). A
        # lutaml model — the JSON mapping, loading and equality are
        # generated from this declaration; no hand-rolled to_h, ever.
        class SarifLog < Lutaml::Model::Serializable
          VERSION = '2.1.0'
          SCHEMA_URI = 'https://json.schemastore.org/sarif-2.1.0.json'

          attribute :version, :string, default: -> { VERSION }
          attribute :schema, :string, default: -> { SCHEMA_URI }
          attribute :runs, 'Ceradoc::Lint::Channel::Sarif::Run',
                    collection: true, default: -> { [] }

          json do
            map :version, to: :version
            map :$schema, to: :schema
            map :runs, to: :runs, render_empty: :as_empty
          end
        end
      end
    end
  end
end
