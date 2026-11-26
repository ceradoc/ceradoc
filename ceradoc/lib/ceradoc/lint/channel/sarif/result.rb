# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    module Channel
      class Sarif
        # One rule finding in SARIF vocabulary (#379): rule id, level,
        # rendered message and locations. A lutaml model — the JSON
        # mapping, loading and equality are generated from this
        # declaration; no hand-rolled to_h, ever.
        class Result < Lutaml::Model::Serializable
          attribute :rule_id, :string
          attribute :level, :string
          attribute :message, 'Ceradoc::Lint::Channel::Sarif::Message'
          attribute :locations, 'Ceradoc::Lint::Channel::Sarif::Location',
                    collection: true

          json do
            map :ruleId, to: :rule_id
            map :level, to: :level
            map :message, to: :message
            map :locations, to: :locations
          end
        end
      end
    end
  end
end
