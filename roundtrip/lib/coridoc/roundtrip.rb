# frozen_string_literal: true

require 'coridoc'
require 'coridoc/asciidoc'
require 'coridoc/markdown'

module Coridoc
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

    autoload :Case, 'coridoc/roundtrip/case'
    autoload :Checker, 'coridoc/roundtrip/checker'
    autoload :Corpus, 'coridoc/roundtrip/corpus'
    autoload :EdgeCases, 'coridoc/roundtrip/edge_cases'
    autoload :Failure, 'coridoc/roundtrip/failure'
    autoload :KnownFailures, 'coridoc/roundtrip/known_failures'
    autoload :Projection, 'coridoc/roundtrip/projection'
    autoload :Snippet, 'coridoc/roundtrip/snippet'
  end
end
