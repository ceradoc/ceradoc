# frozen_string_literal: true

module Coridoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for hyperlink edges.
      class LinkOptions < Edge::Options
        attribute :role, :string
      end
    end
  end
end
