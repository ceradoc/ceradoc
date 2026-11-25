# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      class RejectedPositionalAttribute < Base
        attribute :position, :integer
        attribute :value, :string
      end
    end
  end
end
