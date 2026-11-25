# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Base class for attached elements in AsciiDoc documents.
      #
      # Attached elements are those that can be attached to other elements
      # such as list items or blocks. They include admonitions, paragraphs,
      # and other block types.
      #
      # This class provides the foundation for elements that can be
      # "attached" to parent elements in the document structure.
      #
      # @see Ceradoc::AsciiDoc::Model::Admonition
      # @see Ceradoc::AsciiDoc::Model::Paragraph
      # @see Ceradoc::AsciiDoc::Model::Block::Core
      #
      class Attached < Base
        def block_level?
          true
        end
      end
    end
  end
end
