# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # The tool that produced the run (#379). A lutaml model — the
        # JSON mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Tool < Lutaml::Model::Serializable
          attribute :driver, 'Ceradoc::Lint::Channel::Sarif::Driver'

          json do
            map :driver, to: :driver
          end
        end
      end
    end
  end
end
