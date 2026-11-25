# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      # Section element for organizing document content hierarchically.
      #
      # Sections represent the hierarchical structure of an AsciiDoc document.
      # They can contain nested subsections, paragraphs, and other content.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the section
      # @!attribute [r] content
      #   @return [String, nil] Optional string content (typically unused, see contents)
      # @!attribute [r] title
      #   @return [Title] Section title
      # @!attribute [r] attrs
      #   @return [Array<NamedAttribute>] Additional named attributes
      # @!attribute [r] contents
      #   @return [Array<Paragraph>] Paragraph content within this section
      # @!attribute [r] sections
      #   @return [Array<Section>] Nested subsections
      #
      # @example Create a section
      #   section = Ceradoc::AsciiDoc::Model::Section.new(
      #     title: Ceradoc::AsciiDoc::Model::Title.new("Chapter 1"),
      #     contents: [Ceradoc::AsciiDoc::Model::Paragraph.new("Content here")]
      #   )
      #
      # @example Create nested sections
      #   parent = Ceradoc::AsciiDoc::Model::Section.new(
      #     title: Ceradoc::AsciiDoc::Model::Title.new("Parent Section")
      #   )
      #   child = Ceradoc::AsciiDoc::Model::Section.new(
      #     title: Ceradoc::AsciiDoc::Model::Title.new("Child Section")
      #   )
      #   parent.sections << child
      #
      class Section < Base
        include Ceradoc::AsciiDoc::Model::Anchorable

        def block_level?
          true
        end

        attribute :id, :string
        attribute :content, :string
        attribute :title, Ceradoc::AsciiDoc::Model::Title
        attribute :attrs,
                  Ceradoc::AsciiDoc::Model::NamedAttribute,
                  collection: true,
                  initialize_empty: true
        attribute :contents,
                  Ceradoc::AsciiDoc::Model::Paragraph,
                  collection: true,
                  initialize_empty: true
        attribute :sections,
                  Ceradoc::AsciiDoc::Model::Section,
                  collection: true,
                  initialize_empty: true
        # Block-header attribute list (e.g. `[appendix]`, `[bibliography]`).
        # Single source of truth for the AsciiDoc `[style]` hint; downstream
        # consumers (ceradoc-mirror) read `style` from SectionElement#attributes
        # to dispatch JS section types (annex, references, ...).
        attribute :attribute_list, Ceradoc::AsciiDoc::Model::AttributeList
        # attribute :anchor, Ceradoc::AsciiDoc::Model::Inline::Anchor

        # Style hint derived from the first positional in `attribute_list`.
        # Returns nil when no list is attached. Kept here so callers don't
        # need to know the AttributeList shape.
        def style
          first_positional = attribute_list&.positional&.first
          first_positional&.value
        end

        # Allow setting level directly during initialization
        def initialize(**attributes)
          level_value = attributes.delete(:level)
          super
          if level_value && title
            title.level_int = level_value
          elsif level_value
            self.title = Ceradoc::AsciiDoc::Model::Title.new(content: '', level_int: level_value)
          end
        end

        def validate
          validate_title_type
          super
        end

        # Get the section level from the title
        # @return [Integer, nil] The section level (0-5 for standard sections)
        def level
          title&.level_int
        end

        # Set the section level on the title
        # @param value [Integer] The section level
        def level=(value)
          if title
            title.level_int = value
          else
            self.title = Ceradoc::AsciiDoc::Model::Title.new(content: '', level_int: value)
          end
        end

        def safe_to_collapse?
          title.nil? && sections.empty?
        end

        private

        def validate_title_type
          return if title.nil? || title.is_a?(Ceradoc::AsciiDoc::Model::Title)

          raise TypeError, "title must be a Ceradoc::AsciiDoc::Model::Title, got #{title.class}"
        end
      end
    end
  end
end
