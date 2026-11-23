# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      # Tag element for AsciiDoc documents.
      #
      # Tags are metadata markers that can be associated with document elements.
      #
      # @!attribute [r] name
      #   @return [String] The tag name
      #
      # @!attribute [r] prefix
      #   @return [String] Tag prefix (default: "tag")
      #
      # @!attribute [r] attrs
      #   @return [Coridoc::AsciiDoc::Model::AttributeList] Tag attributes
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create a tag
      #   tag = Coridoc::AsciiDoc::Model::Tag.new
      #   tag.name = "important"
      #
      class Tag < Base
        attribute :name, :string
        attribute :prefix, :string, default: 'tag'
        attribute :attrs, Coridoc::AsciiDoc::Model::AttributeList, default: lambda {
          Coridoc::AsciiDoc::Model::AttributeList.new
        }
        attribute :line_break, :string, default: -> { "\n" }
      end
    end
  end
end
