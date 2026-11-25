# frozen_string_literal: true

module Ceradoc
  module Markdown
    # ListItem model representing an item in a Markdown list.
    #
    class ListItem < Base
      attribute :text, :string
      attribute :checked, :boolean # For task lists (- [ ] or - [x])
      attribute :sublist, Ceradoc::Markdown::List # Nested list
      attribute :children, Ceradoc::Markdown::Base, collection: true, default: []
    end
  end
end
