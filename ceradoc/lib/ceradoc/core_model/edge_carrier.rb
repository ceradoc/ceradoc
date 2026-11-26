# frozen_string_literal: true

module Ceradoc
  module CoreModel
    # Content-graph phase 3: reference-carrying nodes declare their
    # Reference::Edge as a first-class typed attribute (+edges+).
    #
    # A carrier node keeps its convenience fields (+target+, +src+,
    # +alt+, +content+, +options+, +id+) — every transformer, serializer
    # and spec keeps working — but the fields and the Edge are two views
    # of ONE reference: assigning any reference field re-derives the
    # declared Edge (#derive_edge, defined per node family), and
    # reference consumers (Reference::Validation, Reference::Resolution)
    # read +edges+ instead of re-extracting.
    #
    #   image = CoreModel::Image.new(src: 'images/x.png', alt: 'X')
    #   image.edge.kind        # => 'image_ref'
    #   image.edge.address.scheme # => 'path'
    #   image.src = 'https://a.b/x.png'
    #   image.edge.address.scheme # => 'url'
    #
    # The extraction-based derivation (Reference::EdgeSearch) is retired
    # to a cross-check: the edge agreement spec asserts that extraction
    # and the declared attribute agree across the roundtrip corpus.
    #
    # The module is PREPENDED (not included) so its field writers run
    # ahead of the lutaml-generated accessors and can re-derive the Edge
    # through +super+.
    module EdgeCarrier
      # The single Edge this node declares. nil when the node carries no
      # reference (e.g. an Image without +src+).
      def edge
        edges.first
      end

      # Declared edges. Derived from the reference fields on first read
      # and cached on the node; on a frozen node the derivation is
      # pure — a read never mutates (the read-only contract of the
      # reference passes).
      def edges
        declared = super
        return declared unless declared.nil? || declared.empty?
        return derived_edge_array if frozen?

        resync_edge
        super
      end

      # Reference-field writers keep the declared Edge in sync. Writers
      # for attributes a class does not carry are simply never called.
      def target=(value)
        super
        resync_edge
      end

      def src=(value)
        super
        resync_edge
      end

      def alt=(value)
        super
        resync_edge
      end

      def content=(value)
        super
        resync_edge
      end

      def id=(value)
        super
        resync_edge
      end

      def options=(value)
        super
        resync_edge
      end

      private

      # Address parse that never raises: a target no registered scheme
      # can claim (e.g. a markdown link target that still carries its
      # title suffix) declares NO edge — the node keeps its fields, the
      # reference just is not graph-representable. The phase-1
      # extractor raises on the same input; the agreement spec
      # normalizes that to "no edge expected".
      def parse_edge_address(raw, hint: nil)
        Ceradoc::Reference::Address.parse(raw, hint: hint)
      rescue Ceradoc::Reference::Address::ParseError
        nil
      end

      def resync_edge
        self.edges = derived_edge_array
      end

      def derived_edge_array
        derived = derive_edge
        derived ? [derived] : []
      end
    end
  end
end
