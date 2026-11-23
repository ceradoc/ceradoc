# frozen_string_literal: true

module Coridoc
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
        # @param model [Coridoc::AsciiDoc::Model::Base, Array, String] Model to serialize
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
module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload core serializers (flat structure)
        autoload :Base, 'coridoc/asciidoc/serializer/serializers/base'
        autoload :Admonition, 'coridoc/asciidoc/serializer/serializers/admonition'
        autoload :Attribute, 'coridoc/asciidoc/serializer/serializers/attribute'
        autoload :AttributeList, 'coridoc/asciidoc/serializer/serializers/attribute_list'
        autoload :AttributeListAttribute, 'coridoc/asciidoc/serializer/serializers/attribute_list_attribute'
        autoload :Audio, 'coridoc/asciidoc/serializer/serializers/audio'
        autoload :Author, 'coridoc/asciidoc/serializer/serializers/author'
        autoload :Bibliography, 'coridoc/asciidoc/serializer/serializers/bibliography'
        autoload :BibliographyEntry, 'coridoc/asciidoc/serializer/serializers/bibliography_entry'
        autoload :Break, 'coridoc/asciidoc/serializer/serializers/break'
        autoload :CommentBlock, 'coridoc/asciidoc/serializer/serializers/comment_block'
        autoload :CommentLine, 'coridoc/asciidoc/serializer/serializers/comment_line'
        autoload :Document, 'coridoc/asciidoc/serializer/serializers/document'
        autoload :DocumentAttributes, 'coridoc/asciidoc/serializer/serializers/document_attributes'
        autoload :Header, 'coridoc/asciidoc/serializer/serializers/header'
        autoload :Highlight, 'coridoc/asciidoc/serializer/serializers/highlight'
        autoload :Include, 'coridoc/asciidoc/serializer/serializers/include'
        autoload :LineBreak, 'coridoc/asciidoc/serializer/serializers/line_break'
        autoload :NamedAttribute, 'coridoc/asciidoc/serializer/serializers/named_attribute'
        autoload :Paragraph, 'coridoc/asciidoc/serializer/serializers/paragraph'
        autoload :ReviewerNote, 'coridoc/asciidoc/serializer/serializers/reviewer_note'
        autoload :Revision, 'coridoc/asciidoc/serializer/serializers/revision'
        autoload :Section, 'coridoc/asciidoc/serializer/serializers/section'
        autoload :Tag, 'coridoc/asciidoc/serializer/serializers/tag'
        autoload :TableCell, 'coridoc/asciidoc/serializer/serializers/table_cell'
        autoload :TableRow, 'coridoc/asciidoc/serializer/serializers/table_row'
        autoload :Table, 'coridoc/asciidoc/serializer/serializers/table'
        autoload :Term, 'coridoc/asciidoc/serializer/serializers/term'
        autoload :TextElement, 'coridoc/asciidoc/serializer/serializers/text_element'
        autoload :Title, 'coridoc/asciidoc/serializer/serializers/title'
        autoload :Video, 'coridoc/asciidoc/serializer/serializers/video'

        # Autoload submodules (each manages its own autoloads)
        autoload :Block, 'coridoc/asciidoc/serializer/serializers/block'
        autoload :Image, 'coridoc/asciidoc/serializer/serializers/image'
        autoload :Inline, 'coridoc/asciidoc/serializer/serializers/inline'
        autoload :List, 'coridoc/asciidoc/serializer/serializers/list'
      end
    end
  end
end

# Load registrations last (triggers autoload of all serializers)
require_relative 'serializer/registrations'
