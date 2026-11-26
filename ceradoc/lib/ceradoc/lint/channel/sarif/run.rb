# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # One analysis run: the tool and its results (#379). A lutaml
        # model — the JSON mapping, loading and equality are generated
        # from this declaration; no hand-rolled to_h, ever.
        class Run < Lutaml::Model::Serializable
          attribute :tool, 'Ceradoc::Lint::Channel::Sarif::Tool'
          attribute :results, 'Ceradoc::Lint::Channel::Sarif::Result',
                    collection: true, default: -> { [] }

          json do
            map :tool, to: :tool
            map :results, to: :results, render_empty: :as_empty
          end
        end
      end
    end
  end
end
