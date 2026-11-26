# frozen_string_literal: true

module Ceradoc
  # Digital twin of a corpus of source files (#137).
  #
  # A graph of FileNodes mirroring files on disk. Each node materializes
  # lazily in levels — stat (Level 0), digest (Level 1), parsed format
  # tree (Level 2) — and demotes automatically when a lower level goes
  # stale. Staleness is two-part: a node is fresh only if BOTH its
  # content digest AND its include-graph digest (the shape of the files
  # it pulls in) are unchanged. A changed file invalidates its own
  # parsed level and propagates up the include edges to every includer,
  # cycle-safe.
  #
  # The files always win: the twin is read-only derived state, and
  # consumers can never pin a stale level.
  #
  #   graph = Ceradoc::SourceGraph.build("doc.adoc")
  #   node = graph.node("doc.adoc")
  #   node.parsed            # => format tree (parsed on first call)
  #   node.core              # => CoreModel (cached)
  #   graph.stale_nodes      # => nodes whose disk state drifted
  #   graph.persist          # => sidecar for O(changed) warm rebuilds
  #
  # == Incremental builds (#383) ==
  #
  # The change-aware build API. A one-page edit in a 10k-page tree
  # reparses only the edited page and its transitive includers:
  #
  #   graph.stale_nodes   # minimal reparse set, detected from disk
  #                       # (changed files + their transitive includers,
  #                       # nothing else); demotes exactly that set
  #   graph.reparse_set(changed)
  #                       # the same minimal set, computed purely for
  #                       # caller-supplied changed paths — no I/O, no
  #                       # demotion
  #   Ceradoc::SourceGraph.node_digest(node)
  #                       # stage-boundary content hash of the parsed
  #                       # surface model — deterministic across runs
  #                       # and processes; positional bookkeeping
  #                       # (source_line) excluded
  #   Ceradoc::Incremental.plan(graph, changed: paths)
  #                       # => { reparse: [...], reuse: [...] } — the
  #                       # cli#495-facing contract
  module SourceGraph
    autoload :FileNode, "#{__dir__}/source_graph/file_node"
    autoload :Graph, "#{__dir__}/source_graph/graph"
    autoload :Sidecar, "#{__dir__}/source_graph/sidecar"
    autoload :IncludeEdges, "#{__dir__}/source_graph/include_edges"
    autoload :ModelDigest, "#{__dir__}/source_graph/model_digest"

    class << self
      def build(paths, sidecar: Sidecar.default)
        Graph.build(paths, sidecar: sidecar)
      end

      # Stage-boundary content hash of a node's parsed surface model
      # (#383). Deterministic across runs and processes — derived from
      # the model in a fixed canonical order, no object ids, no hash
      # ordering; positional bookkeeping attributes are excluded.
      # Forces the parse level (Level 2) when not yet parsed.
      #
      #   Ceradoc::SourceGraph.node_digest(graph.node("doc.adoc"))
      #
      # @param node [FileNode] a node of the twin
      # @return [String] SHA256 hex digest of the parsed model content
      def node_digest(node)
        ModelDigest.of(node.parsed)
      end
    end
  end
end
