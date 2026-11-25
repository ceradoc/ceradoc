# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Video block element for AsciiDoc documents.
      #
      # Videos are embedded multimedia content with support for various
      # video platforms and custom attributes.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the video
      #
      # @!attribute [r] title
      #   @return [String, nil] Optional video title
      #
      # @!attribute [r] src
      #   @return [String] The video source URL or path
      #
      # @!attribute [r] attributes
      #   @return [Ceradoc::AsciiDoc::Model::Video::AttributeList] Video-specific attributes
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create a video block
      #   video = Ceradoc::AsciiDoc::Model::Video.new
      #   video.src = "https://example.com/video.mp4"
      #   video.title = "Demo Video"
      #
      class Video < Base
        # Autoload nested AttributeList class
        autoload :AttributeList, 'ceradoc/asciidoc/model/video/attribute_list'

        include Ceradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :src, :string, default: -> { '' }
        attribute :attributes,
                  Video::AttributeList,
                  default: lambda {
                    Ceradoc::AsciiDoc::Model::AttributeList.new
                  }
        attribute :line_break, :string, default: -> { "\n" }
      end
    end
  end
end
