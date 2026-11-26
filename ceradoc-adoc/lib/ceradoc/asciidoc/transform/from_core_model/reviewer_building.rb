# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # Reviewer-block reconstruction for the AsciiDoc view:
      # `[reviewer=NAME]\n****\n...\n****`. The CoreModel side is a
      # ReviewerBlock (annotation_label carries the reviewer's name);
      # the adoc side is a ReviewerComment whose body is a CONTAINER of
      # typed children (lists, paragraphs), so the lines rebuild from
      # serialized children rather than a flat-text join (#376).
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

        # Body lines of a typed CONTAINER block: each CoreModel child
        # transforms to its adoc model and serializes, so nested lists
        # and paragraphs keep their shape inside the `****` fence.
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
      end
    end
  end
end
