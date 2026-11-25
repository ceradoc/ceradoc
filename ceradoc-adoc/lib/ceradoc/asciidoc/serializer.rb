# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    # Serializer module for converting AsciiDoc models to AsciiDoc text
    module Serializer
      autoload :AdocSerializer, "#{__dir__}/serializer/adoc_serializer"
      autoload :ElementRegistry, "#{__dir__}/serializer/element_registry"
      autoload :FallbackSerializer, "#{__dir__}/serializer/fallback_serializer"
      autoload :Formatter, "#{__dir__}/serializer/formatter"
      autoload :SpacingStrategy, "#{__dir__}/serializer/spacing_strategy"

      class << self
        # Serialize a model to AsciiDoc format
        # @param model [Ceradoc::AsciiDoc::Model::Base, Array, String] Model to serialize
        # @param options [Hash] Serialization options
        # @return [String] AsciiDoc representation
        def serialize(model, options = {})
          AdocSerializer.serialize(model, options)
        end
      end
    end
  end
end

# Set up Serializers module with autoloads
module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload core serializers (flat structure)
        autoload :Base, 'ceradoc/asciidoc/serializer/serializers/base'
        autoload :Admonition, 'ceradoc/asciidoc/serializer/serializers/admonition'
        autoload :Attribute, 'ceradoc/asciidoc/serializer/serializers/attribute'
        autoload :AttributeList, 'ceradoc/asciidoc/serializer/serializers/attribute_list'
        autoload :AttributeListAttribute, 'ceradoc/asciidoc/serializer/serializers/attribute_list_attribute'
        autoload :Audio, 'ceradoc/asciidoc/serializer/serializers/audio'
        autoload :Author, 'ceradoc/asciidoc/serializer/serializers/author'
        autoload :Bibliography, 'ceradoc/asciidoc/serializer/serializers/bibliography'
        autoload :BibliographyEntry, 'ceradoc/asciidoc/serializer/serializers/bibliography_entry'
        autoload :Break, 'ceradoc/asciidoc/serializer/serializers/break'
        autoload :CommentBlock, 'ceradoc/asciidoc/serializer/serializers/comment_block'
        autoload :CommentLine, 'ceradoc/asciidoc/serializer/serializers/comment_line'
        autoload :Document, 'ceradoc/asciidoc/serializer/serializers/document'
        autoload :DocumentAttributes, 'ceradoc/asciidoc/serializer/serializers/document_attributes'
        autoload :Header, 'ceradoc/asciidoc/serializer/serializers/header'
        autoload :Highlight, 'ceradoc/asciidoc/serializer/serializers/highlight'
        autoload :Include, 'ceradoc/asciidoc/serializer/serializers/include'
        autoload :LineBreak, 'ceradoc/asciidoc/serializer/serializers/line_break'
        autoload :NamedAttribute, 'ceradoc/asciidoc/serializer/serializers/named_attribute'
        autoload :Paragraph, 'ceradoc/asciidoc/serializer/serializers/paragraph'
        autoload :ReviewerNote, 'ceradoc/asciidoc/serializer/serializers/reviewer_note'
        autoload :Revision, 'ceradoc/asciidoc/serializer/serializers/revision'
        autoload :Section, 'ceradoc/asciidoc/serializer/serializers/section'
        autoload :Tag, 'ceradoc/asciidoc/serializer/serializers/tag'
        autoload :TableCell, 'ceradoc/asciidoc/serializer/serializers/table_cell'
        autoload :TableRow, 'ceradoc/asciidoc/serializer/serializers/table_row'
        autoload :Table, 'ceradoc/asciidoc/serializer/serializers/table'
        autoload :Term, 'ceradoc/asciidoc/serializer/serializers/term'
        autoload :TextElement, 'ceradoc/asciidoc/serializer/serializers/text_element'
        autoload :Title, 'ceradoc/asciidoc/serializer/serializers/title'
        autoload :Video, 'ceradoc/asciidoc/serializer/serializers/video'

        # Autoload submodules (each manages its own autoloads)
        autoload :Block, 'ceradoc/asciidoc/serializer/serializers/block'
        autoload :Image, 'ceradoc/asciidoc/serializer/serializers/image'
        autoload :Inline, 'ceradoc/asciidoc/serializer/serializers/inline'
        autoload :List, 'ceradoc/asciidoc/serializer/serializers/list'
      end
    end
  end
end

# Load registrations last (triggers autoload of all serializers)
require_relative 'serializer/registrations'
