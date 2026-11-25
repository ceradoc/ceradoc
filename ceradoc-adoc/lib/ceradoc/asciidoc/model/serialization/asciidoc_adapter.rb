# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Serialization
        # Adapter for AsciiDoc serialization in Lutaml::Model format registry.
        #
        # This is a standalone adapter class that delegates to Ceradoc's
        # parsing infrastructure. It does NOT inherit from Base to avoid
        # circular dependencies with the format registration system.
        #
        class AsciidocAdapter
          # Delegate to Model::Document for AST creation
          def self.from_ast(elements)
            # Lazy reference to avoid loading Document before format is registered
            Ceradoc::AsciiDoc::Model::Document.from_ast(elements)
          end

          # Delegate to Ceradoc.parse for parsing
          def self.parse(string)
            Ceradoc.parse(string)
          end
        end
      end
    end
  end
end
