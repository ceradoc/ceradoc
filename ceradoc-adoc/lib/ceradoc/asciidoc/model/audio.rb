# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Audio block element for AsciiDoc documents.
      #
      # Audio elements are embedded multimedia content with support for
      # various audio formats and custom attributes.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the audio
      #
      # @!attribute [r] title
      #   @return [String, nil] Optional audio title
      #
      # @!attribute [r] src
      #   @return [String] The audio source URL or path
      #
      # @!attribute [r] attributes
      #   @return [Ceradoc::AsciiDoc::Model::AttributeList] Audio attributes
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create an audio block
      #   audio = Ceradoc::AsciiDoc::Model::Audio.new
      #   audio.src = "https://example.com/audio.mp3"
      #   audio.title = "Podcast Episode"
      #
      class Audio < Base
        include Ceradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :src, :string, default: -> { '' }
        attribute :attributes, Ceradoc::AsciiDoc::Model::AttributeList, default: lambda {
          Ceradoc::AsciiDoc::Model::AttributeList.new
        }
        attribute :line_break, :string, default: -> { "\n" }
      end
    end
  end
end
