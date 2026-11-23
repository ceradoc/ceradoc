# frozen_string_literal: true

module Coridoc
  module Markdown
    # List model representing a Markdown list (ordered or unordered).
    #
    # @example Create an unordered list
    #   list = Coridoc::Markdown::List.new(
    #     ordered: false,
    #     items: [
    #       Coridoc::Markdown::ListItem.new(text: "Item 1"),
    #       Coridoc::Markdown::ListItem.new(text: "Item 2")
    #     ]
    #   )
    #
    class List < Base
      attribute :ordered, :boolean, default: false
      attribute :items, Coridoc::Markdown::ListItem, collection: true
      attribute :start_number, :integer, default: 1
    end
  end
end
