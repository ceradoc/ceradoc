# frozen_string_literal: true

module Ceradoc
  # Change-aware build planning over the SourceGraph twin (#383) — the
  # contract the metanorma cli change-aware-builds work consumes.
  #
  #   plan = Ceradoc::Incremental.plan(graph, changed: ["intro.adoc"])
  #   plan[:reparse]  # => minimal set: the changed files + their
  #                   #    transitive includers, nothing else
  #   plan[:reuse]    # => every other node the graph tracks
  #
  # Pure: the only inputs are +changed+ and the graph's in-memory
  # state (its recorded include edges and tracked nodes) — no file
  # I/O, no demotion, nothing mutated. Detecting what changed on disk
  # is the caller's job (git diff, mtime sweep, or
  # +SourceGraph::Graph#stale_nodes+).
  module Incremental
    module_function

    # @param graph [SourceGraph::Graph] a built twin
    # @param changed [String, Array<String>] paths edited since the
    #   last build
    # @return [Hash] +:reparse+ — sorted minimal reparse set (the
    #   changed files plus their transitive includers, per the
    #   include edges recorded at last parse); +:reuse+ — sorted
    #   paths of every other tracked node, whose derived state
    #   remains valid
    def plan(graph, changed:)
      reparse = graph.reparse_set(changed)
      { reparse: reparse, reuse: (graph.nodes.map(&:path) - reparse).sort }
    end
  end
end
