# frozen_string_literal: true

module Ceradoc
  module Reference
    # Reference validation pass (#381).
    #
    # Walks a document's reference Edges, resolves each against a
    # catalog, and reports per-edge results. Unresolved navigation,
    # citation, link, include, image and footnote edges surface as
    # typed, positioned Diagnostics: each carries a code
    # ("<status>_<kind>", e.g. +"missing_navigation"+), a severity, the
    # target Address, and the ORIGIN of the asking node (its path from
    # the document root down to the node that owns the edge).
    #
    #   report = Ceradoc::Reference.validate(doc, catalog: catalog)
    #   report.ok?            # => false
    #   report.unresolved     # => entries whose Result is Missing
    #   report.diagnostics.each do |d|
    #     puts "#{d.code} at #{d.origin}: #{d.message}"
    #   end
    #
    # Validation never mutates the document and never raises on
    # unresolved references — reporting is the whole point.
    module Validation
      autoload :Origin, "#{__dir__}/validation/origin"
      autoload :Diagnostic, "#{__dir__}/validation/diagnostic"
      # Entry and Report share a file; both autoloads point at it.
      autoload :Entry, "#{__dir__}/validation/report"
      autoload :Report, "#{__dir__}/validation/report"
      autoload :Runner, "#{__dir__}/validation/runner"

      class << self
        # Validate every Edge in +document+ against +catalog+.
        #
        # @param document [Ceradoc::CoreModel::Base] the document tree
        # @param catalog [Catalog] index to resolve against
        # @param resolver [Resolver, nil] override the resolution step
        #   (e.g. a Resolver::Chain with remote + Deferred semantics).
        #   When nil, the catalog is asked directly so Ambiguous
        #   candidates are reported instead of silently disambiguated.
        # @return [Validation::Report]
        def run(document, catalog:, resolver: nil)
          Runner.new(catalog: catalog, resolver: resolver).run(document)
        end
      end
    end
  end
end
