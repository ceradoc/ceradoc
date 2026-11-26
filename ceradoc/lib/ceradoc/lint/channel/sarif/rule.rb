# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # One rule descriptor (#379): id = the namespaced code, name =
        # the code again. A lutaml model — the JSON mapping, loading
        # and equality are generated from this declaration; no
        # hand-rolled to_h, ever.
        class Rule < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string

          json do
            map :id, to: :id
            map :name, to: :name
          end
        end
      end
    end
  end
end
