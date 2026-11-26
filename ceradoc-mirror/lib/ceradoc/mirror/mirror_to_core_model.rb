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

      # Text blocks (the paragraph family) carry their flattened display
      # text in CoreModel#content next to their structured #children;
      # builders rebuild children only, so the flattened text is derived
      # here once for every produced block (same single-touchpoint
      # reasoning as propagate_source_line).
      #
      # Scoped to CoreModel::Block: the parsers set `content` on text
      # blocks only — structural elements (documents, sections, headers)
      # keep content nil and their titles/ids carry the text instead.
      # Deriving over structural elements would fabricate content the
      # forward parse never produced.
      #
      # Uses #display_text (not #flat_text) so the derivation matches
      # the parse convention: links contribute their label but not their
      # target, images their alt but not their src. Empty derivations
      # leave content nil — block kinds whose display text is empty
      # (lists, tables) keep nil like the forward parse produced.
      def propagate_content(result)
        return unless result.is_a?(CoreModel::Block)
        return unless result.content.nil?

        derived = Array(result.children).map(&:display_text).join
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

        base = []
        open = []
        node.content.each do |child|
          next unless child.is_a?(Node)

          if child.is_a?(Node::Text)
            append_text_run(child, open, base)
          else
            # Non-text inline nodes (images, breaks, footnote markers)
            # sit between marked runs in the parse tree too — close the
            # open mark groups so the built element lands at the right
            # nesting level.
            close_mark_groups(open, base)
            built = build_node(child)
            base.concat(Array(built)) if built
          end
        end
        close_mark_groups(open, base)
        base
      end

      # ProseMirror stores marked text as flat runs (text + mark list);
      # the CoreModel parse shape is a tree (leaf inline elements carry
      # content only, containers carry child runs). Rebuild the tree by
      # walking the runs: a run whose mark list extends the open path
      # opens a nested group, a run that shrinks it closes groups, and a
      # closed group materializes through its MarkReverseBuilder as the
      # leaf or container shape the forward parse produced.
      OpenMarkGroup = Struct.new(:mark, :items)

      def append_text_run(text_node, open, base)
        text = text_node.text
        return if text.nil? || text.empty?

        marks = Array(text_node.marks)
        shared = mark_prefix_length(open.map(&:mark), marks)

        close_to(shared, open, base)
        marks.drop(shared).each { |mark| open << OpenMarkGroup.new(mark, []) }

        target = open.last ? open.last.items : base
        target << CoreModel::TextContent.new(text: text)
      end

      # Number of leading marks shared between the open group path and
      # the incoming run's mark list, comparing type and attrs so two
      # different links never merge into one group.
      def mark_prefix_length(open_marks, run_marks)
        count = 0
        while count < open_marks.size && count < run_marks.size &&
              same_mark?(open_marks[count], run_marks[count])
          count += 1
        end
        count
      end

      def same_mark?(left, right)
        return false unless left.is_a?(Mark) && right.is_a?(Mark)

        # Compare the full wire shape (type + attrs) so two different
        # links never merge into one group. to_hash is the framework
        # serializer — plain `.attrs` would hit lutaml's method_missing
        # on marks that carry no attrs attribute at all.
        left.to_hash == right.to_hash
      end

      def close_to(depth, open, base)
        close_mark_groups(open, base) while open.size > depth
      end

      def close_mark_groups(open, base)
        group = open.pop
        return unless group

        mark_builder = MarkReverseBuilder.lookup(group.mark.type)
        built = if mark_builder
                  mark_builder.new.build_marked(group.items, group.mark)
                else
                  # Unknown mark type: transparent — keep the runs as-is
                  # rather than losing them.
                  group.items
                end

        parent = open.last ? open.last.items : base
        parent.concat(Array(built))
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
