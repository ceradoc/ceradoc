# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      # Table element for AsciiDoc tables.
      #
      # Represents a table with rows and cells. Tables can have titles,
      # captions, and various formatting options.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the table
      # @!attribute [r] title
      #   @return [String, nil] Optional table title
      # @!attribute [r] rows
      #   @return [Array<TableRow>] Table rows
      # @!attribute [r] content
      #   @return [String, nil] Optional string content
      # @!attribute [r] attrs
      #   @return [AttributeList] Additional table attributes
      #
      # @example Create a simple table
      #   table = Coridoc::AsciiDoc::Model::Table.new
      #   table.rows << Coridoc::AsciiDoc::Model::TableRow.new
      #
      class Table < Base
        include Coridoc::AsciiDoc::Model::Anchorable

        def block_level?
          true
        end

        attribute :id, :string
        attribute :title, :string
        attribute :rows, Coridoc::AsciiDoc::Model::TableRow, collection: true
        attribute :content, :string
        # attribute :anchor, Inline::Anchor, default: -> {
        #   id.nil? ? nil : Inline::Anchor.new(id)
        # }
        attribute :attrs, Coridoc::AsciiDoc::Model::AttributeList
      end
    end
  end
end
