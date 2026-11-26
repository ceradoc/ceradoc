# frozen_string_literal: true

module Ceradoc
  module Reference
    module Catalog
      # Multi-document catalog. Ingests a set of documents (or files) and
      # indexes every Content node by its Address.
      #
      #   collection = Catalog::Collection.new
      #   collection.ingest(doc_a, path: 'ELF-5005-1', origin: 'a.adoc')
      #   collection.ingest_file('specs/b.adoc', document_path: 'ELF-5005-2')
      #   collection.lookup(Address.parse('ELF-5005-1#sec-3'))
      #
      # ## Identity-keyed merge
      #
      # Content carries its identity as an Address (the document path for
      # the root, anchor addresses for nested nodes). When two sources
      # carry same-identity Content, BOTH are kept and marked with
      # provenance (origin + ingest lineage) — ingest is never fatal and
      # never overwrites. Lookup resolves duplicates by lineage: the
      # first-ingested source wins and +lookup+ returns a single Content.
      # The full candidate set stays reachable via +entries+ and
      # +provenance+.
      #
      # Because lineage decides, a Collection is never ambiguous:
      # +ambiguous?+ is always false (cross-catalog ambiguity remains a
      # Composite concern).
      class Collection
        include Catalog::Protocol

        # One ingested source document.
        # +identity+ is the document-level Address (nil when ingested
        # without a path); +catalog+ is the per-source Local index;
        # +lineage+ is the ingest sequence number (0-based).
        Source = Struct.new(:document, :identity, :origin, :catalog, :lineage,
                            keyword_init: true)

        # One indexed (Address, Content) pair with provenance.
        Entry = Struct.new(:address, :content, :origin, :lineage,
                           keyword_init: true)

        attr_reader :sources

        def initialize
          @sources = []
          @entries = {}
        end

        class << self
          # Ingest a set of documents at once. Entries may be bare
          # documents or (document, path) pairs.
          #
          #   Collection.from_documents([doc_a, [doc_b, 'ELF-5005-2']])
          def from_documents(documents)
            collection = new
            documents.each do |entry|
              document, path = entry.is_a?(Array) ? entry : [entry, nil]
              collection.ingest(document, path: path)
            end
            collection
          end
        end

        # Ingest one document. +path:+ is the document identity ("ELF-5005-1"
        # or the scoped "ELF:5005:1"); +origin:+ names where the document
        # came from (defaults to the path). Never raises on duplicates —
        # same-identity content merges by lineage.
        def ingest(document, path: nil, origin: nil)
          identity = path ? build_identity(path) : nil
          local = Local.from_doc(document, path: path)
          source = Source.new(
            document: document,
            identity: identity,
            origin: origin || path,
            catalog: local,
            lineage: @sources.size
          )
          @sources << source
          index_source!(source)
          source
        end

        # Parse a file through the format registry and ingest it. The
        # origin defaults to the file path. Requires a format gem for the
        # file's extension to be registered (like the rest of Ceradoc).
        def ingest_file(file_path, document_path: nil, origin: nil, format: nil)
          document = Ceradoc::Pipeline.parse_file(file_path, format: format)
          ingest(document, path: document_path, origin: origin || file_path)
        end

        # Ingest a set of files at once.
        def ingest_files(file_paths, **)
          file_paths.map { |file_path| ingest_file(file_path, **) }
        end

        # Lineage-first lookup: the earliest-ingested Content for the
        # Address, or nil. Same-identity duplicates never surface here.
        def lookup(address)
          entry = entries(address).first
          entry&.content
        end

        # Every Entry ever indexed under the Address, oldest lineage
        # first. Returns a copy — callers cannot corrupt the index.
        def entries(address)
          Array(@entries[address]).dup
        end

        # Origins of every Content matching the Address, oldest first.
        def provenance(address)
          entries(address).map(&:origin)
        end

        # True when more than one source carries this identity. The
        # duplicates are still resolved by lineage in +lookup+; this is
        # an informational view for tooling.
        def duplicate?(address)
          entries(address).size > 1
        end

        # Duplicates resolve by lineage — a Collection never reports
        # ambiguity. Cross-catalog ambiguity is a Composite concern.
        def ambiguous?(_address)
          false
        end

        # Every (Address, Content) pair across all sources, including
        # same-identity duplicates from different sources.
        def each_pair(&)
          return to_enum(:each_pair) unless block_given?

          @entries.each_value do |entries|
            entries.each { |entry| yield entry.address, entry.content }
          end
        end

        def recognizes_scheme?(scheme)
          @sources.any? { |source| source.catalog.recognizes_scheme?(scheme) }
        end

        def size
          @entries.size
        end

        private

        def build_identity(path)
          hint = path.include?(':') ? :scoped_path : :path
          Address.parse(path, hint: hint)
        end

        def index_source!(source)
          source.catalog.each_pair do |address, content|
            entry = Entry.new(
              address: address,
              content: content,
              origin: source.origin,
              lineage: source.lineage
            )
            @entries[address] = Array(@entries[address]) << entry
          end
        end
      end
    end
  end
end
