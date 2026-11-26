# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Parser
      # The compiled-grammar backend: the shipped artifact
      # (grammar/ceradoc-adoc.parg is the single source of truth), its
      # embedded model-bindings table, and the compile task that
      # produces the artifact from the .parg plus the bindings sidecar.
      module GrammarBackend
        GRAMMAR_DIR = File.expand_path('../../../../grammar', __dir__)
        SOURCE_PATH = File.join(GRAMMAR_DIR, 'ceradoc-adoc.parg')
        ARTIFACT_PATH = File.join(GRAMMAR_DIR, 'ceradoc-adoc.artifact.json')
        BINDINGS_PATH = File.join(GRAMMAR_DIR, 'ceradoc-adoc.bindings.yml')

        class << self
          def parse(string, **)
            parse_entry('document', string, **)
          end

          # Parse +string+ from a named artifact entry (document,
          # text_any, list) and materialize the tree.
          def parse_entry(entry, string, **)
            TreeMaterializer.convert(artifact.parse(entry, string, **))
          end

          # The rule -> model table embedded in the artifact (nil if none).
          def model_bindings
            artifact.envelope['model_bindings']
          end

          # True when the artifact was compiled from the current source
          # (parsanol freshness, recorded source hash).
          def fresh_against?(source)
            artifact.fresh_against?(source)
          end

          # Compile the .parg to its artifact JSON text, embedding the
          # bindings sidecar (validated by the core loader, embedded and
          # checksum-sealed by parsanol's ModelBindings).
          def compile_source
            require 'parsanol/parg'
            document = Parsanol::PARG::Parser.new(File.read(SOURCE_PATH)).parse
            envelope = Parsanol::PARG::Compiler.compile(document).envelope
            envelope = Parsanol::PARG::ModelBindings.embed(envelope, Ceradoc::BindingInflater.load_table(BINDINGS_PATH))
            Parsanol::PARG::Compiler.seal_json(envelope)
          end

          private

          def artifact
            require 'parsanol/parg'
            @artifact ||= Parsanol::PARG::Artifact.load(ARTIFACT_PATH)
          end
        end
      end
    end
  end
end
