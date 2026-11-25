# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Inline
        # Footnote inline element for AsciiDoc documents.
        #
        # Footnotes are referenced with numeric IDs: footnote:[text] or footnoteref:[id].
        #
        # @!attribute [r] text
        #   @return [String] The footnote text content
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional footnote reference ID
        #
        # @example Create a footnote
        #   footnote = Ceradoc::AsciiDoc::Model::Inline::Footnote.new
        #   footnote.text = "Additional information"
        #   footnote.to_adoc # => "footnote:[Additional information]"
        #
        # @example Create a footnote reference
        #   footnote = Ceradoc::AsciiDoc::Model::Inline::Footnote.new
        #   footnote.id = "note1"
        #   footnote.to_adoc # => "footnoteref:[note1]"
        #
        class Footnote < Base
          attribute :text, :string
          attribute :id, :string
        end
      end
    end
  end
end
