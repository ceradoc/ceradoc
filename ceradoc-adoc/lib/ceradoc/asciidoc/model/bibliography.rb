# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Bibliography block element for AsciiDoc documents.
      #
      # Bibliographies contain lists of bibliography entries (references)
      # with support for various citation styles.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the bibliography
      #
      # @!attribute [r] title
      #   @return [String, nil] Optional bibliography title
      #
      # @!attribute [r] entries
      #   @return [Array<Ceradoc::AsciiDoc::Model::BibliographyEntry>] Bibliography entry items
      #
      # @example Create a bibliography
      #   bib = Ceradoc::AsciiDoc::Model::Bibliography.new
      #   bib.title = "References"
      #   entry = Ceradoc::AsciiDoc::Model::BibliographyEntry.new
      #   bib.entries << entry
      #
      # @see Ceradoc::AsciiDoc::Model::BibliographyEntry Individual bibliography entries
      #
      class Bibliography < Base
        include Ceradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :entries, Ceradoc::AsciiDoc::Model::BibliographyEntry, collection: true
      end
    end
  end
end
