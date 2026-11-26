# frozen_string_literal: true

module Ceradoc
  module Reference
    module Catalog
      # Scheme-aware catalog backed by a fetcher — typically a network
      # client, a document service, or any object answering
      # +fetch(address)+ with a Content node (or nil when absent).
      #
      #   remote = Catalog::Remote.new(
      #     schemes: %i[url scoped_path],
      #     fetcher: DocService::Fetcher.new
      #   )
      #
      # The catalog is LAZY: nothing is fetched at construction and
      # +lookup+ asks the fetcher once per call. It enumerates no pairs —
      # a remote index has no local truth to walk — so +each_pair+ yields
      # nothing. Compose it into a Composite catalog or a Resolver::Chain
      # to combine remote reach with local indexes; schemes the remote
      # does not list stay unresolvable (the resolver surfaces them as
      # Deferred, never as a fabricated miss).
      class Remote
        include Catalog::Protocol

        attr_reader :schemes, :fetcher

        def initialize(schemes:, fetcher:)
          @schemes = Array(schemes).map(&:to_sym)
          @fetcher = fetcher
        end

        def lookup(address)
          return nil unless recognizes_scheme?(address.scheme)

          fetcher.fetch(address)
        end

        # A lazy catalog has nothing to enumerate.
        def each_pair(&)
          return to_enum(:each_pair) { 0 } unless block_given?

          nil
        end

        def recognizes_scheme?(scheme)
          @schemes.include?(scheme.to_sym)
        end
      end
    end
  end
end
