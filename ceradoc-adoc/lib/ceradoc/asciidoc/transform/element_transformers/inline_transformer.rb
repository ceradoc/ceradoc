# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        # Owns the recursive re-parse that recognises nested inline marks
        # (Bug 16B). The re-parse re-enters the full inline pipeline:
        #
        #   transform_inline → parse_nested_inline_children
        #     → ToCoreModel.parse_and_transform_inline
        #       → InlineTransformVisitor.visit
        #         → ToCoreModel.transform
        #           → transform_inline (cycle)
        #
        # The cycle terminates when the mark's content has no further
        # inline-mark characters — the parser produces only flat text,
        # `parse_nested_inline_children` returns `[]`, and the mark
        # keeps its flat content shape.
        #
        # Realistic nesting is 2–3 levels. Pathological input
        # (`*****…*****` with hundreds of levels) raises
        # `SystemStackError` naturally — that's Ruby's contract, not a
        # bespoke guard.
        class InlineTransformer
          class << self
            def transform_inline(inline, format_type)
              klass = Ceradoc::CoreModel::InlineElement.format_type_class(format_type)
              raw_content = ToCoreModel.extract_text_content(inline.content)

              # Recursively parse the mark's content to recognise nested
              # inline marks (Bug 16B). Only populate `children` when the
              # parser found real nested marks — flat marks keep children
              # empty, and the Mirror handler's `build_simple_mark` falls
              # back to the `content` string. Saves one TextContent
              # allocation per flat mark (the common case).
              children = parse_nested_inline_children(raw_content)

              kwargs = { content: raw_content, source_line: inline.source_line }
              kwargs[:children] = children if children.any?
              constraint = recorded_constraint(inline)
              kwargs[:constraint] = constraint if constraint
              klass.new(**kwargs)
            end

            # AsciiDoc mark models carry `unconstrained` when the grammar
            # distinguished the marker spelling; record it on the
            # CoreModel element so serialization can honor the original
            # spelling instead of re-guessing (#332).
            def recorded_constraint(inline)
              return nil unless inline.class.attributes.key?(:unconstrained)

              inline.unconstrained ? 'unconstrained' : 'constrained'
            end

            # Re-parse a mark's raw content string through the inline
            # parser. Returns the list of CoreModel children when the
            # content contains nested inline marks; returns [] when
            # the content is plain text (no nested marks to preserve).
            # The empty return is the recursion terminator.
            def parse_nested_inline_children(text)
              return [] if text.nil? || text.to_s.empty?

              parsed = ToCoreModel.parse_and_transform_inline(text.to_s)
              return [] unless parsed.is_a?(Array)

              has_marks = parsed.any? do |child|
                child.is_a?(Ceradoc::CoreModel::InlineElement)
              end
              has_marks ? parsed : []
            end

            def transform_inline_text(inline, format_type)
              klass = Ceradoc::CoreModel::InlineElement.format_type_class(format_type)
              klass.new(
                content: inline.text.to_s,
                source_line: inline.source_line
              )
            end

            def transform_inline_footnote(footnote)
              parsed_content = ToCoreModel.parse_and_transform_inline(footnote.text.to_s)
              Ceradoc::CoreModel::FootnoteElement.new(
                target: footnote.id,
                content: parsed_content,
                source_line: footnote.source_line
              )
            end

            def transform_link(link)
              Ceradoc::CoreModel::LinkElement.new(
                target: link.path,
                content: link.name || link.path,
                source_line: link.source_line
              )
            end

            def transform_cross_reference(xref)
              Ceradoc::CoreModel::CrossReferenceElement.new(
                target: xref.href,
                content: xref.args&.first || xref.href,
                source_line: xref.source_line
              )
            end

            def transform_stem(stem)
              Ceradoc::CoreModel::StemElement.new(
                content: stem.content,
                stem_type: stem.type || 'stem',
                source_line: stem.source_line
              )
            end
          end
        end
      end
    end
  end
end
