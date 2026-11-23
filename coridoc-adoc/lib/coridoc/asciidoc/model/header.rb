# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      # Document header containing title and metadata.
      #
      # The Header represents the document-level metadata including the main title,
      # author information, and revision details. This corresponds to the AsciiDoc
      # header line (e.g., `= Document Title`) and associated metadata.
      #
      # @!attribute [r] title
      #   @return [String] The main document title
      # @!attribute [r] author
      #   @return [Author, nil] Document author information
      # @!attribute [r] revision
      #   @return [Revision, nil] Document revision information (version, date)
      #
      # @example Create a simple header
      #   header = Coridoc::AsciiDoc::Model::Header.new(title: "My Document")
      #
      # @example Create a header with author and revision
      #   header = Coridoc::AsciiDoc::Model::Header.new(
      #     title: "My Document",
      #     author: Coridoc::AsciiDoc::Model::Author.new("John Doe"),
      #     revision: Coridoc::AsciiDoc::Model::Revision.new("1.0", "2024-01-01")
      #   )
      #
      class Header < Base
        include Coridoc::AsciiDoc::Model::Anchorable

        attribute :title, Coridoc::AsciiDoc::Model::Title
        attribute :author, Coridoc::AsciiDoc::Model::Author
        attribute :revision, Coridoc::AsciiDoc::Model::Revision

        def validate
          validate_author_type
          validate_revision_type
        end

        private

        def validate_author_type
          return if author.nil? || author.is_a?(Coridoc::AsciiDoc::Model::Author)

          raise TypeError, "author must be a Coridoc::AsciiDoc::Model::Author, got #{author.class}"
        end

        def validate_revision_type
          return if revision.nil? || revision.is_a?(Coridoc::AsciiDoc::Model::Revision)

          raise TypeError, "revision must be a Coridoc::AsciiDoc::Model::Revision, got #{revision.class}"
        end
      end
    end
  end
end
