# frozen_string_literal: true

require 'parsanol'
require 'parsanol/convenience'

module Coridoc
  module AsciiDoc
    module Parser
      # Autoload parser modules - they will be loaded when included in Base class below
      autoload :Admonition, 'coridoc/asciidoc/parser/admonition'
      autoload :AttributeList, 'coridoc/asciidoc/parser/attribute_list'
      autoload :Bibliography, 'coridoc/asciidoc/parser/bibliography'
      autoload :Block, 'coridoc/asciidoc/parser/block'
      autoload :BlockHeader, 'coridoc/asciidoc/parser/block_header'
      autoload :Citation, 'coridoc/asciidoc/parser/citation'
      autoload :Content, 'coridoc/asciidoc/parser/content'
      autoload :DocumentAttributes, 'coridoc/asciidoc/parser/document_attributes'
      autoload :Header, 'coridoc/asciidoc/parser/header'
      autoload :Inline, 'coridoc/asciidoc/parser/inline'
      autoload :List, 'coridoc/asciidoc/parser/list'
      autoload :Paragraph, 'coridoc/asciidoc/parser/paragraph'
      autoload :RuleDispatcher, 'coridoc/asciidoc/parser/rule_dispatcher'
      autoload :Section, 'coridoc/asciidoc/parser/section'
      autoload :Table, 'coridoc/asciidoc/parser/table'
      autoload :Term, 'coridoc/asciidoc/parser/term'
      autoload :Text, 'coridoc/asciidoc/parser/text'
      autoload :Stem, 'coridoc/asciidoc/parser/stem'

      class Base < Parsanol::Parser
        include Admonition
        include AttributeList
        include Bibliography
        include Block
        include BlockHeader
        include Citation
        include Content
        include DocumentAttributes
        include Header
        include Inline
        include List
        include Paragraph
        include Section
        include Table
        include Term
        include Text
        include Stem

        root :document

        rule(:document) do
          (
            header.as(:header) |
            document_attributes |
            section |
            admonition_line |
            bib_entry |
            block |
            block_image |
            comment_block |
            comment_line |
            include_directive |
            list |
            table.as(:table) |
            page_break.as(:page_break) |
            paragraph |
            tag |
            empty_line.as(:line_break) |
            any.as(:unparsed)
          ).repeat.as(:document)
        end

        # Parse an AsciiDoc file
        # @param filename [String] The filename of the Asciidoc file to parse
        # @return [Hash] The parsed AST object
        def self.parse_file(filename)
          parse(File.read(filename))
        end

        # Parse an AsciiDoc string
        # @param string [String] The Asciidoc string to parse
        # @return [Hash] The parsed AST object
        def self.parse(string)
          new.parse(string)
        rescue Parsanol::ParseFailed => e
          warn e.parse_failure_cause.ascii_tree
        end

        # The compiled PARG artifact (grammar/coridoc-adoc.parg, the
        # single source of truth) is the parse backend; the Ruby-DSL
        # grammar defined by this class remains the parity reference
        # (parg_parity_spec + engine_differential_spec assert the two
        # produce identical trees). The artifact routes through
        # parsanol's compiled-program fast lane (parsanol-ruby#162,
        # 1.3.81) and parses native by default; the historical
        # ruby-mode artifact divergence is fixed (#185, 1.3.82).
        def parse(string, **)
          GrammarBackend.parse(string, **)
        end

        def rule_dispatch(rule_name, *, **)
          RuleDispatcher.dispatch(self, rule_name, *, **)
        end

        # Per-instance dispatch cache used by RuleDispatcher. Encapsulated
        # accessor — the dispatcher reads this instead of poking
        # instance_variable_get/set. Lazy-initialized; returns the same
        # Hash across calls on the same instance.
        def _rule_dispatch_cache
          @_rule_dispatch_cache ||= {}
        end
      end

      # Lazily-loaded compiled-grammar backend (the shipped artifact).
      module GrammarBackend
        class << self
          def parse(string, **)
            parse_entry('document', string, **)
          end

          # Parse +string+ from a named artifact entry (document,
          # text_any, list) and materialize the tree.
          def parse_entry(entry, string, **)
            TreeMaterializer.convert(artifact.parse(entry, string, **))
          end

          private

          def artifact
            require 'parsanol/parg'
            @artifact ||= Parsanol::PARG::Artifact.load(
              File.expand_path('../../../../grammar/coridoc-adoc.artifact.json', __dir__)
            )
          end
        end
      end

      # Wrap every parser rule for Parsanol memoization. Must run after all
      # parser modules are included in Base so that instance_method(rule_name)
      # finds the methods defined by every module.
      RuleDispatcher.apply(Base)
    end
  end
end
