# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # A file position plus optional region (#379). A lutaml
        # model — the JSON mapping, loading and equality are
        # generated from this declaration; no hand-rolled to_h, ever.
        class PhysicalLocation < Lutaml::Model::Serializable
          attribute :artifact_location,
                    'Ceradoc::Lint::Channel::Sarif::ArtifactLocation'
          attribute :region, 'Ceradoc::Lint::Channel::Sarif::Region'

          json do
            map :artifactLocation, to: :artifact_location
            map :region, to: :region
          end
        end
      end
    end
  end
end
