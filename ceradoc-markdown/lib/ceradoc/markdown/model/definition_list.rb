# frozen_string_literal: true

module Ceradoc
  module Markdown
    # DefinitionList model representing a Kramdown definition list.
    #
    # Definition lists consist of terms followed by one or more definitions.
    # The syntax uses `:` to start a definition.
    #
    # @example Simple definition list
    #   list = Ceradoc::Markdown::DefinitionList.new(
    #     items: [
    #       Ceradoc::Markdown::DefinitionTerm.new(
    #         text: "kramdown",
    #         definitions: [
    #           Ceradoc::Markdown::DefinitionItem.new(content: "A Markdown parser")
    #         ]
    #       )
    #     ]
    #   )
    #
    # Syntax:
    #   term
    #   : definition content
    #
    #   multiple terms
    #   : first definition
    #   : second definition
    #
    class DefinitionList < Base
      # Terms with their definitions
      attribute :items, Ceradoc::Markdown::DefinitionTerm, collection: true
    end
  end
end
