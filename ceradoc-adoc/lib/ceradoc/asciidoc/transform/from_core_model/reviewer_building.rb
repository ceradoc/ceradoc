# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # Reviewer/cast-block reconstruction for the AsciiDoc view.
      # Reviewer blocks are `[reviewer=NAME]\n****\n...\n****` (the
      # reviewer's name rides on ReviewerBlock#annotation_label); cast
      # open blocks carry a positional style ([abstract], [partintro]).
      # Their bodies are CONTAINERS of typed children (lists,
      # paragraphs), so the lines rebuild from serialized children
      # rather than a flat-text join (#376).
      module ReviewerBuilding
        # `[reviewer=NAME]` attribute list rebuilt from the
        # ReviewerBlock's annotation_label (see ToCoreModel
        # transform_reviewer_block).
        def reviewer_attributes(block)
          list = Ceradoc::AsciiDoc::Model::AttributeList.new
          label = block.annotation_label
          return list if label.nil? || label.to_s.empty?

          list.add_named('reviewer', label.to_s)
          list
        end

        # Positional cast attribute line for typed open blocks:
        # `[abstract]`, `[partintro]`.
        def cast_attributes(semantic)
          list = Ceradoc::AsciiDoc::Model::AttributeList.new
          list.add_positional(semantic.to_s)
          list
        end

        # Body lines of a typed CONTAINER block: when the children
        # carry structure the prose string cannot represent (lists,
        # nested blocks, inline markup), each CoreModel child
        # transforms to its adoc model and serializes; plain prose
        # keeps the flat-text path.
        def container_lines(block, content_text)
          if container_children?(block)
            container_block_lines(block)
          else
            content_text.split("\n")
          end
        end

        # Body lines from serialized children, trimmed of the blank
        # lines block serializers add at their open and close.
        def container_block_lines(block)
          models = flatten_children(Array(block.children))
          rendered = models.map { |model| Ceradoc::AsciiDoc::Serializer.serialize(model) }.join
          rendered.split("\n", -1).tap do |lines|
            # Block serializers open and close with blank lines; a
            # blank line right after the opening fence changes how the
            # following blocks record their spacing, so trim both ends.
            lines.shift while lines.size > 1 && lines.first.empty?
            lines.pop while lines.size > 1 && lines.last.empty?
          end
        end

        private

        # A child is plain when it is a paragraph with only TextContent
        # children — the prose string represents it faithfully. Anything
        # else (lists, nested blocks, inline markup) needs the
        # structured rebuild.
        def container_children?(block)
          Array(block.children).any? do |child|
            next true unless child.is_a?(CoreModel::ParagraphBlock)

            Array(child.children).any?(CoreModel::InlineElement)
          end
        end
      end
    end
  end
end
