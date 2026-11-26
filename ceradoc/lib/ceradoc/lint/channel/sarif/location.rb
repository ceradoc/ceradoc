# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # One finding location (#379). A lutaml model — the JSON
        # mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Location < Lutaml::Model::Serializable
          attribute :physical_location,
                    'Ceradoc::Lint::Channel::Sarif::PhysicalLocation'

          json do
            map :physicalLocation, to: :physical_location
          end
        end
      end
    end
  end
end
