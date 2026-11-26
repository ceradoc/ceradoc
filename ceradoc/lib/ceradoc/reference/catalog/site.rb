# frozen_string_literal: true

module Ceradoc
  module Reference
    module Catalog
      # Component/version/module-style scoping layers over a Collection.
      #
      # A Site is a FILTERED VIEW — it owns no storage. Every lookup is
      # answered by the wrapped collection's sources whose document
      # identity falls inside the site's scope.
      #
      #   site = Catalog::Site.new(
      #     collection: collection,
      #     component: 'ELF', version: '5005', module_name: '1'
      #   )
      #   site.lookup(Address.parse('ELF:5005:1#sec-3'))  # in scope
      #   site.lookup(Address.parse('ELF:5006:1'))        # nil — out of scope
      #
      # Scope layers are optional; a nil layer is a wildcard. Document
      # identities decompose positionally:
      #
      #   "ELF:5005:1" (scoped_path)  => component ELF, version 5005, module 1
      #   "ELF-5005-1" (path)         => component ELF, version 5005, module 1
      #
      # Addresses that carry no scope but target the site's component are
      # qualified on lookup: a site scoped to component ELF resolves the
      # path Address "5005:1#sec-3" as "ELF:5005:1#sec-3". Anchors are
      # never qualified — they are searched across the covered sources in
      # ingest order (lineage-first).
      class Site
        include Catalog::Protocol

        # The scoping layers. +module_name+ (not +module+ — reserved word)
        # is the third layer of the component/version/module tuple.
        Scope = Struct.new(:component, :version, :module_name,
                           keyword_init: true)

        PATH_IDENTITY_SEPARATOR = '-'
        private_constant :PATH_IDENTITY_SEPARATOR

        attr_reader :collection, :scope

        def initialize(collection:, component: nil, version: nil,
                       module_name: nil)
          @collection = collection
          @scope = Scope.new(
            component: component,
            version: version,
            module_name: module_name
          )
        end

        # Sources of the wrapped collection whose document identity falls
        # inside this site's scope, in ingest (lineage) order.
        def covered_sources
          collection.sources.select { |source| covers_identity?(source.identity) }
        end

        # Does a document-identity Address fall inside the scope?
        # An unscoped site (all layers nil) covers everything, including
        # sources with no identity. A scoped site covers only identities
        # it can decompose and match layer-by-layer.
        def covers_identity?(identity)
          return true if empty_scope?

          return false if identity.nil?
          return false unless %w[scoped_path path].include?(identity.scheme)

          layers = decompose(identity)
          return false unless layers

          matches_layers?(layers)
        end

        def lookup(address)
          return nil unless accepts?(address)

          target = qualify(address)
          covered_sources.each do |source|
            hit = source.catalog.lookup(target)
            return hit if hit
          end
          nil
        end

        # Enumerates (Address, Content) pairs of the covered sources only.
        def each_pair(&)
          return to_enum(:each_pair) unless block_given?

          covered_sources.each do |source|
            source.catalog.each_pair(&)
          end
        end

        def recognizes_scheme?(scheme)
          return true if scheme.to_sym == :scoped_path && scope.component

          covered_sources.any? do |source|
            source.catalog.recognizes_scheme?(scheme)
          end
        end

        # Documents inside the scope, in lineage order.
        def documents
          covered_sources.map(&:document)
        end

        private

        def empty_scope?
          scope.to_a.compact.empty?
        end

        # An Address is accepted when it does not name a scope this site
        # does not cover. A scoped Address outside the site's component
        # is a miss, not an error.
        def accepts?(address)
          return true unless address.scope
          return true unless scope.component

          address.scope == scope.component
        end

        # Qualify a bare path target with the site's component so a
        # scoped site can answer unscoped asks ("5005:1" inside
        # component ELF). The qualified form follows the corpus's
        # identity style: scoped identities qualify as scoped_path
        # ("ELF" + "5005:1"), dash-separated identities prefix the
        # component ("ELF" + "5005-1"). Anchors and URLs are never
        # rewritten; corpora without document identities are not
        # qualified either.
        def qualify(address)
          return address unless scope.component
          return address unless address.scheme.to_sym == :path

          case identity_scheme
          when 'scoped_path'
            Address.new(
              scheme: 'scoped_path',
              scope: scope.component,
              target: address.target,
              fragment: address.fragment
            )
          when 'path'
            Address.new(
              scheme: 'path',
              target: "#{scope.component}#{PATH_IDENTITY_SEPARATOR}#{address.target}",
              fragment: address.fragment
            )
          else
            address
          end
        end

        # Identity style of the corpus, from the first covered source
        # that carries one. Nil when no covered source has an identity.
        def identity_scheme
          @identity_scheme ||=
            covered_sources.filter_map { |s| s.identity&.scheme }.first
        end

        # Positional decomposition of a document identity into the
        # (component, version, module_name) layers. Returns nil when the
        # identity cannot be decomposed positionally.
        def decompose(identity)
          if identity.scheme == 'scoped_path'
            parts = identity.target.to_s.split(':')
            Scope.new(
              component: identity.scope,
              version: parts[0],
              module_name: parts[1]
            )
          else
            parts = identity.target.to_s.split(PATH_IDENTITY_SEPARATOR)
            return nil if parts.size < 3

            Scope.new(
              component: parts[0],
              version: parts[1],
              module_name: parts[2]
            )
          end
        end

        def matches_layers?(layers)
          return false if scope.component && layers.component != scope.component
          return false if scope.version && layers.version != scope.version
          return false if scope.module_name && layers.module_name != scope.module_name

          true
        end
      end
    end
  end
end
