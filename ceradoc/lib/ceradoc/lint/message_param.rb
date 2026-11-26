# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Lint
    # One typed message interpolation slot. Diagnostics carry message
    # references plus these params; channels (or a message catalog)
    # render the locale text. Value is a string — params are display
    # data, not typed domain values.
    class MessageParam < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :value, :string
    end
  end
end
