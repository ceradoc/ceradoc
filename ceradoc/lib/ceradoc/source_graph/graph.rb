# frozen_string_literal: true

require 'digest'

module Ceradoc
  module SourceGraph
    # The graph facade. Owns nodes by real path, the includer→includee
    # edges derived from parsed documents, and the staleness contract:
    # a node is fresh only if its content digest AND its include-graph
    # digest are unchanged. Drift demotes the node and propagates up
    # the edges (cycle-safe).
    class Graph
      attr_reader :sidecar

      # @param paths [Array<String>] root files to track
      # @param sidecar [Sidecar, nil] persistence; defaults to the XDG
      #   cache sidecar
      def initialize(paths: [], sidecar: Sidecar.default)
        @nodes = {}
        @sidecar = sidecar
        @edges = {} # includer path => [includee paths]
        Array(paths).each { |path| node(path) }
      end

      # Build a graph from root files, warming digest levels from the
      # sidecar so a warm rebuild parses only changed files.
      def self.build(paths, sidecar: Sidecar.default)
        graph = new(paths: paths, sidecar: sidecar)
        graph.warm
        graph
      end

      def node(path)
        key = File.expand_path(path)
        @nodes[key] ||= load_node(key)
      end

      def nodes
        @nodes.values
      end

      # Parse +core+ (Level 2 + materialization), record include
      # edges, and link target nodes into the graph.
      def materialize(node)
        node.core.tap { record_edges(node) }
      end

      # Paths a node includes, from its last parse.
      def edges(path)
        @edges[File.expand_path(path)] || []
      end

      # Includers of a path, from recorded edges.
      def includers(path)
        key = File.expand_path(path)
        @edges.select { |_includer, targets| targets.include?(key) }.keys
      end

      # The MINIMAL reparse set for +changed+ paths (#383): the changed
      # files themselves plus every transitive includer, per the
      # include edges recorded at last parse. Nothing else — untouched
      # subtrees are not pulled in. Pure: reads only the in-memory
      # edge map — no file I/O, no demotion — so it is safe to call
      # for planning. Cycle-safe. Sorted for determinism.
      #
      #   graph.reparse_set("intro.adoc")
      #   # => ["intro.adoc", "root.adoc"] — sorted absolute paths
      #
      # @param changed [String, Array<String>] paths that changed
      # @return [Array<String>] absolute paths that must be reparsed
      def reparse_set(changed)
        queue = Array(changed).map { |path| File.expand_path(path) }
        return [] if queue.empty?

        includer_map = @edges.each_with_object({}) do |(includer, targets), map|
          targets.each { |target| (map[target] ||= []) << includer }
        end

        visited = {}
        until queue.empty?
          path = queue.shift
          next if visited[path]

          visited[path] = true
          queue.concat(includer_map[path] || [])
        end
        visited.keys.sort
      end

      # Nodes whose derived state no longer mirrors disk: content
      # drift or include-graph drift. Returns the MINIMAL reparse set
      # — the drifted nodes plus every transitive includer, nothing
      # else — and demotes exactly those nodes. Cycle-safe, sorted.
      def refresh
        changed = nodes.select { |n| !n.fresh? || graph_drifted?(n) }
                       .map(&:path)
        stale = reparse_set(changed).filter_map { |path| @nodes[path] }
        stale.each(&:demote)
        stale
      end

      def stale_nodes
        refresh
      end

      # A node's include-graph digest: the shape of what it pulls in,
      # paired with each target's content digest. Recompute after
      # edge recording; store on the node.
      def compute_graph_digest(node)
        edges(node.path)
        node.graph_digest = digest_shape(edges(node.path))
      end

      def persist
        nodes.each { |n| compute_graph_digest(n) if n.parsed? }
        records = nodes.map do |n|
          { path: n.path, id: n.id, digest: n.digest,
            edges: edges(n.path) }
        end
        sidecar.write(records).each do |rec|
          n = @nodes[rec[:path]]
          n.id = rec[:id] if n
        end
        self
      end

      # Seed digest levels and edges from the sidecar without
      # parsing. Graph digests derive from warmed edges + digests —
      # the sidecar stores only source facts, never derived state.
      def warm
        sidecar.entries.each_key do |key|
          node(key) if File.exist?(key)
        end
        sidecar.entries.each do |key, record|
          node(key).digest_warm(record['digest'])
          targets = Array(record['edges']).select { |t| File.exist?(t) }
          next if targets.empty?

          @edges[key] = targets
          targets.each { |t| node(t) }
          node(key).graph_digest = digest_shape(targets)
        end
        self
      end

      private

      def load_node(key)
        record = sidecar.record_for(key)
        FileNode.new(key, id: record && record['id'])
      end

      def record_edges(node)
        targets = IncludeEdges.targets(node.core, base_dir: File.dirname(node.path))
        @edges[node.path] = targets
        compute_graph_digest(node)
        targets.each { |t| node(t) }
      end

      # Structural drift: the recorded include-graph digest differs
      # from the one recomputed over current content digests.
      def graph_drifted?(node)
        return false if node.graph_digest.nil?

        node.graph_digest != current_graph_digest(node)
      end

      def current_graph_digest(node)
        digest_shape(edges(node.path))
      end

      # Content digest over the include-graph shape: which files this
      # node pulls in, paired with their content digests.
      def digest_shape(targets)
        lines = targets.map { |t| "#{t}:#{digest_of(t)}" }.sort.join("\n")
        Digest::SHA256.hexdigest(lines)
      end

      def digest_of(path)
        n = @nodes[File.expand_path(path)]
        n ? n.digest : Digest::SHA256.file(path).hexdigest
      end
    end
  end
end
