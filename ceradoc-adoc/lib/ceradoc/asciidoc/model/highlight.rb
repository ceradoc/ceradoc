# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      class Highlight < TextElement
        attribute :unconstrained, :boolean, default: -> { false }
      end
    end
  end
end
