# frozen_string_literal: true

module Ceradoc
  module Mirror
    # Transforms ProseMirror-compatible Mirror nodes back into CoreModel.
    #
    # Dispatch is delegated to ReverseBuilder (node-level) and
    # MarkReverseBuilder (mark-level) — adding a new node or mark type is
    # done by registering a new Builder class, with no edit to this file
    # (OCP). ReverseBuilder and MarkReverseBuilder are autoloaded from
    # ceradoc/mirror.rb; referencing them here triggers load of the
    # registry files, which is where the built-in builders self-register.
    class MirrorToCoreModel
      def call(mirror_node)
        build_node(mirror_node)
      end

      def build_node(node)
        builder_class = ReverseBuilder.lookup(node.type)
        raise Error, "Unknown mirror node type: #{node.type}" unless builder_class

        result = builder_class.new(self).build(node)
        propagate_source_line(result, node)
        propagate_content(result)
        result
      end

      # Blocks carry their flattened text in CoreModel#content next to
      # their structured #children; builders rebuild children only, so
      # the flattened text is derived here once for every produced node
      # (same single-touchpoint reasoning as propagate_source_line).
      # Empty derivations leave content nil — block kinds whose
      # flat_text is empty (lists, tables) keep nil like the forward
      # parse produced.
      def propagate_content(result)
        return unless result.is_a?(CoreModel::Base)

        attrs = result.class.attributes.keys
        return unless attrs.include?(:content) && attrs.include?(:children)
        return unless result.content.nil?

        derived = Array(result.children).map(&:flat_text).join
        result.content = derived unless derived.empty?
      rescue StandardError
        result
      end

      # Copy parser-attached source_line from the Mirror node onto every
      # CoreModel node the builder produced. Single touchpoint for the
      # entire Mirror → CoreModel direction — builders stay focused on
      # per-type mapping and don't repeat this concern (DRY).
      def propagate_source_line(result, node)
        return unless node.is_a?(Node)

        line = node.source_line
        return unless line

        Array(result).each do |built|
          next unless built.is_a?(CoreModel::Base)
          next if built.source_line

          built.source_line = line
        end
      end

      # ── Shared helpers (single source of truth — used by every
      # ReverseBuilder::Base subclass via delegation) ──

      def build_content(node)
        return [] unless node.content

        node.content.flat_map do |child|
          result = build_node(child)
          next [] if result.nil?

          result.is_a?(Array) ? result : [result]
        end
      end

      # Mark dispatch goes through MarkReverseBuilder so adding a new
      # mark type is purely additive (OCP parity with node dispatch).
      # Unknown marks pass `inner` through unchanged.
      def apply_mark(inner, mark)
        builder_class = MarkReverseBuilder.lookup(mark.type)
        return inner unless builder_class

        builder_class.new.build(inner, mark)
      end

      def build_inline_children(node)
        return [] unless node.content

        node.content.filter_map do |child|
          next unless child.is_a?(Node)

          build_node(child)
        end
      end

      def extract_text(node)
        return node.text.to_s if node.is_a?(Node::Text)
        return '' unless node.content

        node.content.filter_map do |child|
          child.is_a?(Node) ? extract_text(child) : ''
        end.join
      end

      def inline_content(element)
        element.is_a?(CoreModel::InlineElement) ? element.content : element.to_s
      end
    end
  end
end
