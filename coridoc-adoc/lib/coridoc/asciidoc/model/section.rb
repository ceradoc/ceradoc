# frozen_string_literal: true

module Coridoc
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
      #   section = Coridoc::AsciiDoc::Model::Section.new(
      #     title: Coridoc::AsciiDoc::Model::Title.new("Chapter 1"),
      #     contents: [Coridoc::AsciiDoc::Model::Paragraph.new("Content here")]
      #   )
      #
      # @example Create nested sections
      #   parent = Coridoc::AsciiDoc::Model::Section.new(
      #     title: Coridoc::AsciiDoc::Model::Title.new("Parent Section")
      #   )
      #   child = Coridoc::AsciiDoc::Model::Section.new(
      #     title: Coridoc::AsciiDoc::Model::Title.new("Child Section")
      #   )
      #   parent.sections << child
      #
      class Section < Base
        include Coridoc::AsciiDoc::Model::Anchorable

        def block_level?
          true
        end

        attribute :id, :string
        attribute :content, :string
        attribute :title, Coridoc::AsciiDoc::Model::Title
        attribute :attrs,
                  Coridoc::AsciiDoc::Model::NamedAttribute,
                  collection: true,
                  initialize_empty: true
        attribute :contents,
                  Coridoc::AsciiDoc::Model::Paragraph,
                  collection: true,
                  initialize_empty: true
        attribute :sections,
                  Coridoc::AsciiDoc::Model::Section,
                  collection: true,
                  initialize_empty: true
        # Block-header attribute list (e.g. `[appendix]`, `[bibliography]`).
        # Single source of truth for the AsciiDoc `[style]` hint; downstream
        # consumers (coridoc-mirror) read `style` from SectionElement#attributes
        # to dispatch JS section types (annex, references, ...).
        attribute :attribute_list, Coridoc::AsciiDoc::Model::AttributeList
        # attribute :anchor, Coridoc::AsciiDoc::Model::Inline::Anchor

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
            self.title = Coridoc::AsciiDoc::Model::Title.new(content: '', level_int: level_value)
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
            self.title = Coridoc::AsciiDoc::Model::Title.new(content: '', level_int: value)
          end
        end

        def safe_to_collapse?
          title.nil? && sections.empty?
        end

        private

        def validate_title_type
          return if title.nil? || title.is_a?(Coridoc::AsciiDoc::Model::Title)

          raise TypeError, "title must be a Coridoc::AsciiDoc::Model::Title, got #{title.class}"
        end
      end
    end
  end
end
