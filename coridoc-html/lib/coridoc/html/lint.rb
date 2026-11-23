# frozen_string_literal: true

module Coridoc
  module Html
    # HTML lint rules: model-driven checks over the parsed CoreModel
    # element array that Coridoc::Html.parse produces. Rules
    # self-register into Coridoc::Lint.registry when required.
    module Lint
      require_relative 'lint/registrations'

      RULES = Registrations::RULES

      RULES.each { |rule| Coridoc::Lint.registry.register(rule) }
    end
  end
end
