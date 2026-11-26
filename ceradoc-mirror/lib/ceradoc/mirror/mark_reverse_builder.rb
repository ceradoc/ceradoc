# frozen_string_literal: true

module Ceradoc
  module Mirror
    # OCP-compliant registry for Mirror mark -> CoreModel transformation.
    #
    # This is the mark-level counterpart to ReverseBuilder (which handles
    # node-level dispatch). Adding support for a new mark type is purely
    # additive:
    #
    #   module MarkReverseBuilder
    #     class Concept < Base
    #       registers 'concept'
    #
    #       def element_class
    #         CoreModel::TermElement
    #       end
    #     end
    #   end
    #
    # No edits to MirrorToCoreModel or any other existing class.
    #
    # ## Rebuild shapes (parse parity)
    #
    # The AsciiDoc parse produces two InlineElement shapes, and the
    # reverse side must reproduce the same one it started from:
    #
    #   * LEAF — a single text run carries the mark. Parse shape:
    #     +BoldElement(content: "bold")+ with NO children (the dual-shape
    #     content-only form). Built by {#build_marked} when the group
    #     holds exactly one TextContent.
    #   * CONTAINER — several runs (text + nested leaf elements) share
    #     the mark. Parse shape: +ItalicElement(children: [...],
    #     content: <display text>)+. Built when the group holds more
    #     than one run or a nested element.
    module MarkReverseBuilder
      REGISTRY = {}

      module_function

      def register(type, builder_class)
        REGISTRY[type] = builder_class
      end

      def lookup(type)
        REGISTRY[type]
      end

      def registered_types
        REGISTRY.keys
      end

      # Base class for all mark reverse builders. Subclasses register one
      # mark type string via `registers`, declare {#element_class}, and —
      # for marks that carry attrs (link href, xref target, stem type) —
      # override {#build_marked} to forward them.
      class Base
        def self.registers(*types)
          types.each { |t| MarkReverseBuilder.register(t, self) }
        end

        # The CoreModel::InlineElement subclass this mark reverses to.
        def element_class
          raise NotImplementedError,
                "#{self.class} must declare #element_class"
        end

        # Legacy single-dispatch entry (MirrorToCoreModel#apply_mark and
        # ReverseBuilder::Text mark reduction). `inner` is the already
        # built CoreModel inline content this mark wraps.
        def build(inner, mark)
          build_marked(inner, mark)
        end

        # Rebuild the parse shape for the runs grouped under this mark.
        # `children` is one TextContent (leaf) or an array of runs
        # (container); `mark` is the source Mirror::Mark for attrs.
        def build_marked(children, _mark)
          runs = Array(children)
          if runs.one? && runs.first.is_a?(CoreModel::TextContent)
            element_class.new(content: runs.first.text)
          else
            element_class.new(children: runs, content: display_join(runs))
          end
        end

        private

        def display_join(runs)
          Array(runs).map(&:display_text).join
        end
      end

      # ── Simple wraps: typed InlineElement subclass, no attrs ──

      class Bold < Base
        registers 'strong'

        def element_class
          CoreModel::BoldElement
        end
      end

      class Italic < Base
        registers 'emphasis'

        def element_class
          CoreModel::ItalicElement
        end
      end

      class Monospace < Base
        registers 'code'

        def element_class
          CoreModel::MonospaceElement
        end
      end

      class Underline < Base
        registers 'underline'

        def element_class
          CoreModel::UnderlineElement
        end
      end

      class Strikethrough < Base
        registers 'strike'

        def element_class
          CoreModel::StrikethroughElement
        end
      end

      class Subscript < Base
        registers 'subscript'

        def element_class
          CoreModel::SubscriptElement
        end
      end

      class Superscript < Base
        registers 'superscript'

        def element_class
          CoreModel::SuperscriptElement
        end
      end

      class Highlight < Base
        registers 'highlight'

        def element_class
          CoreModel::HighlightElement
        end
      end

      # ── Marks with attrs ──

      class Link < Base
        registers 'link'

        def element_class
          CoreModel::LinkElement
        end

        def build_marked(children, mark)
          runs = Array(children)
          attrs = { target: mark.attrs&.href }
          if leaf_run?(runs)
            element_class.new(content: runs.first.text, **attrs)
          else
            element_class.new(children: runs,
                              content: display_join(runs), **attrs)
          end
        end

        private

        def leaf_run?(runs)
          runs.one? && runs.first.is_a?(CoreModel::TextContent)
        end
      end

      class CrossReference < Base
        registers 'xref'

        def element_class
          CoreModel::CrossReferenceElement
        end

        def build_marked(children, mark)
          runs = Array(children)
          attrs = { target: mark.attrs&.target }
          if leaf_run?(runs)
            resolved = mark.attrs&.resolved
            element_class.new(content: resolved || runs.first.text, **attrs)
          else
            element_class.new(children: runs,
                              content: display_join(runs), **attrs)
          end
        end

        private

        def leaf_run?(runs)
          runs.one? && runs.first.is_a?(CoreModel::TextContent)
        end
      end

      class Stem < Base
        registers 'stem'

        def element_class
          CoreModel::StemElement
        end

        def build_marked(children, mark)
          runs = Array(children)
          attrs = { stem_type: mark.attrs&.stem_type }
          if runs.one? && runs.first.is_a?(CoreModel::TextContent)
            element_class.new(content: runs.first.text, **attrs)
          else
            element_class.new(children: runs,
                              content: display_join(runs), **attrs)
          end
        end
      end

      class Span < Base
        registers 'span'

        def element_class
          CoreModel::SpanElement
        end

        def build_marked(children, mark)
          runs = Array(children)
          role = mark.attrs&.role
          attrs = role ? { element_attributes: role_attributes(role) } : {}
          if runs.one? && runs.first.is_a?(CoreModel::TextContent)
            element_class.new(content: runs.first.text, **attrs)
          else
            element_class.new(children: runs,
                              content: display_join(runs), **attrs)
          end
        end

        private

        def role_attributes(role)
          [CoreModel::ElementAttribute.new(name: 'role', value: role)]
        end
      end
    end
  end
end
