# frozen_string_literal: true

module Ceradoc
  module Html
    # HTML lint rules: model-driven checks over the parsed CoreModel
    # element array that Ceradoc::Html.parse produces. Rules
    # self-register into Ceradoc::Lint.registry when required.
    module Lint
      require_relative 'lint/registrations'

      RULES = Registrations::RULES

      RULES.each { |rule| Ceradoc::Lint.registry.register(rule) }
    end
  end
end
