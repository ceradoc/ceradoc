# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Reviewer note block element for AsciiDoc documents.
      #
      # Reviewer notes capture feedback from document reviewers with
      # metadata about who provided the feedback and when.
      #
      # @!attribute [r] reviewer
      #   @return [String, nil] Name of the reviewer
      #
      # @!attribute [r] date
      #   @return [String, nil] Date of the review
      #
      # @!attribute [r] from
      #   @return [String, nil] Review start indicator
      #
      # @!attribute [r] to
      #   @return [String, nil] Review end indicator
      #
      # @!attribute [r] content
      #   @return [Array<Ceradoc::AsciiDoc::Model::Base>] Polymorphic content (paragraphs, lists, admonitions, etc.)
      #
      # @example Create a reviewer note
      #   note = Ceradoc::AsciiDoc::Model::ReviewerNote.new
      #   note.reviewer = "John Doe"
      #   note.date = "2024-01-15"
      #   note.content = [Ceradoc::AsciiDoc::Model::Paragraph.new]
      #
      class ReviewerNote < Base
        # Reviewer note attributes
        attribute :reviewer, :string
        attribute :date, :string
        attribute :from, :string
        attribute :to, :string

        # Content can be any AsciiDoc elements (paragraphs, lists, etc.)
        attribute :content,
                  Ceradoc::AsciiDoc::Model::Base,
                  polymorphic: [
                    Ceradoc::AsciiDoc::Model::TextElement,
                    Ceradoc::AsciiDoc::Model::Paragraph,
                    Ceradoc::AsciiDoc::Model::Admonition,
                    Ceradoc::AsciiDoc::Model::LineBreak,
                    Ceradoc::AsciiDoc::Model::List::Core
                  ]
      end
    end
  end
end
