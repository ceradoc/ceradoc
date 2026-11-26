# frozen_string_literal: true

module Ceradoc
  module Reference
    # Extraction-based edge derivation — retired to a VALIDATOR.
    #
    # Phase 3 moved Edges to first-class attributes: reference-carrying
    # nodes (CrossReferenceElement, LinkElement, Image, Include,
    # FootnoteElement) declare their Edge via +CoreModel::EdgeCarrier+
    # and keep it in sync with their fields. Reference::Validation and
    # Reference::Resolution consume the declared +edges+ attribute.
    #
    # This module remains as the independent phase-1 derivation from the
    # raw node fields: the edge agreement spec walks the roundtrip
    # corpus asserting that extraction and the declared attribute agree
    # — drift on either side fails the suite.
    #
    # The walker is read-only: it never mutates the input tree.
    module EdgeSearch
      module_function

      # Yields (parent_node, edge) for every Edge found in the tree.
      # The parent_node is the node that owns the edge — the
      # materializer replaces the edge in-place inside parent_node's
      # children list.
      def each_edge(root)
        return to_enum(:each_edge, root) unless block_given?

        walk(root) { |node| edges_for(node).each { |edge| yield node, edge } }
      end

      # Walk tree, yield each Base node. Stops at inline leaves.
      def walk(node, &block)
        return unless node.is_a?(Ceradoc::CoreModel::Base)
        return unless block

        yield(node)
        return unless node.is_a?(Ceradoc::CoreModel::HasChildren)

        children = node.children
        return unless children

        children.each { |child| walk(child, &block) }
      end

      # Extract every Edge the given node owns. Pure function of node.
      def edges_for(node)
        edge_extractor = EDGE_EXTRACTORS[node.class]
        return [] unless edge_extractor

        edge = edge_extractor.call(node)
        edge ? [edge] : []
      end

      def edge_from_cross_reference(node)
        Edge.build(
          kind: :navigation,
          address: parse_address(node.target, hint: xref_hint(node.target)),
          source_id: node.id,
          label: node.content
        )
      end

      def edge_from_link(node)
        Edge.build(
          kind: :link,
          address: parse_address(node.target),
          source_id: node.id,
          label: node.content
        )
      end

      def edge_from_include(node)
        Edge.build(
          kind: :include,
          address: parse_address(node.target, hint: path_or_url_hint(node.target)),
          source_id: node.id,
          options: { include_options: node.options }
        )
      end

      def edge_from_image(node)
        Edge.build(
          kind: :image_ref,
          address: parse_address(node.src, hint: path_or_url_hint(node.src)),
          source_id: node.id,
          label: node.alt,
          options: { alt_text: node.alt }
        )
      end

      def edge_from_footnote(node)
        Edge.build(
          kind: :footnote_ref,
          address: parse_address(node.target || node.id, hint: :anchor),
          source_id: node.id,
          options: { footnote_id: node.id }
        )
      end

      # Xref and file-like hint policies live with the Address domain
      # (the carriers use the same helpers for their declared edges).
      def xref_hint(target)
        Ceradoc::Reference::Address.xref_hint(target)
      end

      def path_or_url_hint(target)
        Ceradoc::Reference::Address.path_or_url_hint(target)
      end

      def parse_address(target, hint: nil)
        Ceradoc::Reference::Address.parse(target.to_s, hint: hint)
      end

      EDGE_EXTRACTORS = {
        Ceradoc::CoreModel::CrossReferenceElement => method(:edge_from_cross_reference),
        Ceradoc::CoreModel::LinkElement => method(:edge_from_link),
        Ceradoc::CoreModel::Include => method(:edge_from_include),
        Ceradoc::CoreModel::Image => method(:edge_from_image),
        Ceradoc::CoreModel::FootnoteElement => method(:edge_from_footnote)
      }.freeze
      private_constant :EDGE_EXTRACTORS
    end
  end
end
