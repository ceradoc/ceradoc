# frozen_string_literal: true

module Coridoc
  module Markdown
    # Markdown lint rules (#165 follow-up): model-driven checks over
    # the Markdown model tree. Rules self-register into
    # Coridoc::Lint.registry when this file is required.
    module Lint
      require_relative 'lint/registrations'

      RULES = Registrations::RULES

      RULES.each { |rule| Coridoc::Lint.registry.register(rule) }
    end
  end
end
