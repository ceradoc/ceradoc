# frozen_string_literal: true

module Ceradoc
  module Markdown
    # List model representing a Markdown list (ordered or unordered).
    #
    # @example Create an unordered list
    #   list = Ceradoc::Markdown::List.new(
    #     ordered: false,
    #     items: [
    #       Ceradoc::Markdown::ListItem.new(text: "Item 1"),
    #       Ceradoc::Markdown::ListItem.new(text: "Item 2")
    #     ]
    #   )
    #
    class List < Base
      attribute :ordered, :boolean, default: false
      attribute :items, Ceradoc::Markdown::ListItem, collection: true
      attribute :start_number, :integer, default: 1
    end
  end
end
