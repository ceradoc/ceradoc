# frozen_string_literal: true

module Ceradoc
  module CoreModel
    # Represents an image in a document
    #
    # Images can be block-level (standalone) or inline. They support
    # various attributes like alt text, dimensions, and linking.
    #
    # @example Creating a block image
    #   image = CoreModel::Image.new(
    #     src: "images/diagram.png",
    #     alt: "System Architecture",
    #     caption: "Figure 1: System Overview",
    #     width: "800px"
    #   )
    #
    # @example Creating an inline image
    #   icon = CoreModel::Image.new(
    #     src: "icons/warning.png",
    #     alt: "Warning",
    #     inline: true
    #   )
    class Image < Base
      prepend Ceradoc::CoreModel::EdgeCarrier

      # @!attribute src
      #   @return [String, nil] source URL or path to the image
      attribute :src, :string

      # @!attribute alt
      #   @return [String, nil] alternative text for accessibility
      attribute :alt, :string

      # @!attribute caption
      #   @return [String, nil] caption text for the image
      attribute :caption, :string

      # @!attribute width
      #   @return [String, nil] image width (e.g., '100%', '500px')
      attribute :width, :string

      # @!attribute height
      #   @return [String, nil] image height (e.g., '300px', 'auto')
      attribute :height, :string

      # @!attribute link
      #   @return [String, nil] URL to link to when image is clicked
      attribute :link, :string

      # @!attribute role
      #   @return [String, nil] CSS role/class for the image (AsciiDoc role attr)
      attribute :role, :string

      # @!attribute inline
      #   @return [Boolean] whether this is an inline image
      attribute :inline, :boolean, default: -> { false }

      # @!attribute float
      #   @return [String, nil] float position ('left', 'right')
      #   @note Not yet wired by any transformer; reserved for future use
      attribute :float, :string

      # @!attribute edges
      #   @return [Array<Ceradoc::Reference::Edge>] the declared
      #     image-reference Edge (maintained from +src+ / +alt+)
      attribute :edges, 'Ceradoc::Reference::Edge', collection: true

      # The image-reference Edge: alt text is the label and is carried
      # in the options as well. File-like sources are paths; URLs stay
      # URLs.
      def derive_edge
        return if src.nil? || src.empty?

        address = parse_edge_address(
          src, hint: Ceradoc::Reference::Address.path_or_url_hint(src)
        )
        return if address.nil?

        Ceradoc::Reference::Edge.build(
          kind: :image_ref,
          address: address,
          source_id: id,
          label: alt,
          options: { alt_text: alt }
        )
      end

      # Flat text carries the alt text and the source so text-extraction
      # contexts keep the image reference that raw-string paragraphs
      # used to include.
      def flat_text
        "#{alt}#{src}"
      end

      # Display text carries the alt only — the parsers' `content`
      # attribute records the alt, never the source path.
      def display_text
        alt.to_s
      end

      private

      def comparable_attributes
        super + %i[src alt caption width height link role inline]
      end
    end
  end
end
