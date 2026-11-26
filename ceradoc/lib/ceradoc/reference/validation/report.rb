# frozen_string_literal: true

module Ceradoc
  module Reference
    module Validation
      # Outcome of one validated Edge: the Edge, its resolution Result,
      # and the typed Diagnostic when the outcome is not a clean hit.
      Entry = Struct.new(:edge, :result, :diagnostic, keyword_init: true)

      # Per-edge validation results, plus typed views over them.
      # Entries keep every edge — resolved ones included — so callers
      # can audit coverage; +unresolved+ and +diagnostics+ expose the
      # problems.
      class Report
        include Enumerable

        attr_reader :entries

        def initialize(entries)
          @entries = entries.freeze
        end

        def each(&)
          entries.each(&)
        end

        # Edges no catalog resolved (Result::Missing) — the unresolved
        # navigation/citation/link/include/image/footnote set, each with
        # its origin info attached.
        def unresolved
          entries.select { |entry| entry.result.missing? }
        end

        # Edges whose scheme no resolver handles.
        def deferred
          entries.select { |entry| entry.result.deferred? }
        end

        def diagnostics
          entries.filter_map(&:diagnostic)
        end

        def errors
          diagnostics.select(&:error?)
        end

        def warnings
          diagnostics.select(&:warning?)
        end

        # True when nothing failed: no missing references.
        def ok?
          errors.empty?
        end

        def size
          entries.size
        end
        alias length size
      end
    end
  end
end
