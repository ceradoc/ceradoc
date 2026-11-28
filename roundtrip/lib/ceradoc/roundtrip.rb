# frozen_string_literal: true

require 'ceradoc'
require 'ceradoc/asciidoc'
require 'ceradoc/markdown'

module Ceradoc
  # Round-trip property harness for the CoreModel hub.
  #
  # For a source text T in format F the harness checks, per construct:
  #
  #   core1 = parse(T)        T1 = serialize(core1)
  #   core2 = parse(T1)       T2 = serialize(core2)
  #
  #   model stability  projection(core1) == projection(core2)
  #   canonical form   T2 == T1   (T1 is the canonical form of T)
  #
  # See roundtrip/CANONICAL_FORM.md for the policy.
  module Roundtrip
    ROOT = File.expand_path('../..', __dir__)
    REPO_ROOT = File.expand_path('..', ROOT)
    FORMATS = %i[asciidoc markdown].freeze

    autoload :Case, 'ceradoc/roundtrip/case'
    autoload :Checker, 'ceradoc/roundtrip/checker'
    autoload :Corpus, 'ceradoc/roundtrip/corpus'
    autoload :EdgeCases, 'ceradoc/roundtrip/edge_cases'
    autoload :Failure, 'ceradoc/roundtrip/failure'
    autoload :KnownFailures, 'ceradoc/roundtrip/known_failures'
    autoload :Projection, 'ceradoc/roundtrip/projection'
    autoload :Snippet, 'ceradoc/roundtrip/snippet'
    autoload :Vector, 'ceradoc/roundtrip/vector'
    autoload :VectorHarness, 'ceradoc/roundtrip/vector_harness'
    autoload :VectorSealer, 'ceradoc/roundtrip/vector_sealer'
  end
end
