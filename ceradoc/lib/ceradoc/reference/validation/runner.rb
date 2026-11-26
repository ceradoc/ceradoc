# frozen_string_literal: true

module Ceradoc
  module Reference
    module Validation
      # Walks the document tree tracking each node's origin path, reads
      # the Edges each node declares (the +edges+ attribute maintained
      # by CoreModel::EdgeCarrier), resolves them, and collects one
      # Entry per edge. Read-only: the input tree is never mutated.
      class Runner
        attr_reader :catalog, :resolver

        def initialize(catalog:, resolver: nil)
          @catalog = catalog
          @resolver = resolver
        end

        def run(document)
          entries = []
          walk(document, []) { |node, path| collect(node, path, entries) }
          Report.new(entries)
        end

        private

        # Depth-first walk carrying the path of node labels from the
        # root. Strings and non-model leaves are skipped.
        def walk(node, path, &block)
          return unless node.is_a?(Ceradoc::CoreModel::Base)

          path_here = path + [label_for(node)]
          yield(node, path_here)
          return unless node.is_a?(Ceradoc::CoreModel::HasChildren)

          children = node.children
          return unless children

          children.each { |child| walk(child, path_here, &block) }
        end

        def collect(node, path, entries)
          declared_edges(node).each do |edge|
            result = resolve(edge)
            diagnostic = nil
            unless result.resolved?
              diagnostic = Diagnostic.for_result(
                edge: edge, result: result, origin: origin_for(node, path)
              )
            end
            entries << Entry.new(
              edge: edge, result: result, diagnostic: diagnostic
            )
          end
        end

        # The declared +edges+ attribute is the primary source (phase
        # 3); extraction (EdgeSearch) survives only as the agreement
        # cross-check in the spec suite.
        def declared_edges(node)
          return [] unless node.is_a?(Ceradoc::CoreModel::EdgeCarrier)

          node.edges
        end

        # Without an explicit resolver the catalog is asked directly so
        # Ambiguous candidates surface as reportable results instead of
        # being collapsed by an ambiguity policy.
        def resolve(edge)
          return resolver.resolve(edge) if resolver

          return Result::Missing.build(edge: edge, address: edge.address) unless
            catalog.recognizes_scheme?(edge.address.scheme)

          hit = catalog.lookup(edge.address)
          case hit
          when nil
            Result::Missing.build(edge: edge, address: edge.address)
          when Array
            Result::Ambiguous.build(edge: edge, address: edge.address,
                                    candidates: hit)
          else
            Result::Resolved.build(edge: edge, address: edge.address,
                                   target: hit)
          end
        end

        def origin_for(node, path)
          Origin.new(node_path: path.join(' > '), node_id: node.id)
        end

        def label_for(node)
          name = node.class.name.split('::').last
          node.id ? "#{name}##{node.id}" : name
        end
      end
    end
  end
end
