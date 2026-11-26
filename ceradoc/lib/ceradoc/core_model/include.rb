# frozen_string_literal: true

module Ceradoc
  module CoreModel
    # First-class include directive node in the canonical document model.
    #
    # An include directive is a LINK from one document to another file.
    # Parsing preserves these nodes verbatim — no file I/O happens during
    # parse. The result is a text graph: a document referencing other
    # documents via Include edges.
    #
    # Splicing the linked content inline is an explicit, separate step:
    # +Ceradoc.resolve_includes(doc, base_dir:)+ walks the tree and
    # replaces each Include node with the parsed content of its target,
    # recursing into the result.
    #
    # This separation lets callers:
    #   - inspect the graph before deciding to flatten
    #   - resolve with different base dirs / resolvers without re-parsing
    #   - treat includes as external links (e.g. when parsing a site)
    #
    # Attributes:
    #   target       String           path or URL as authored
    #   options      IncludeOptions   parsed selectors (tags/lines/leveloffset/indent/encoding)
    #   raw_options  String           original bracket body, preserved for verbatim round-trip
    #   line_break   String           trailing line break, default "\n"
    #
    # The node is block-level: it appears in the +content+ / +children+
    # array of any block container (Document, Section, Paragraph, List
    # item, Table cell, etc.) alongside other block-level nodes.
    class Include < Base
      prepend Ceradoc::CoreModel::EdgeCarrier
      attribute :target, :string
      attribute :options, Ceradoc::CoreModel::IncludeOptions,
                default: -> { Ceradoc::CoreModel::IncludeOptions.new }
      attribute :raw_options, :string, default: -> { '' }
      attribute :line_break, :string, default: -> { "\n" }
      attribute :edges, 'Ceradoc::Reference::Edge', collection: true

      def self.semantic_type
        :include
      end

      # The include Edge: the directive links this document to another
      # file. File-like targets are paths; URLs stay URLs.
      def derive_edge
        return if target.nil? || target.empty?

        address = parse_edge_address(
          target, hint: Ceradoc::Reference::Address.path_or_url_hint(target)
        )
        return if address.nil?

        Ceradoc::Reference::Edge.build(
          kind: :include,
          address: address,
          source_id: id,
          options: { include_options: options }
        )
      end
    end
  end
end
