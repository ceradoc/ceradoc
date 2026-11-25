# frozen_string_literal: true

# ceradoc-markdown - Markdown document model, parser, and serializer
#
# This gem provides Markdown support for the Ceradoc document processing library.
# It includes:
# - Markdown Document Model (Ceradoc::Markdown::*)
# - Markdown Parser (CommonMark-compliant, Parsanol-based)
# - Markdown Serializer (round-trip capable)
# - Kramdown extensions support (IAL, ALD, math, TOC)
#
# @example Basic usage
#   require 'ceradoc/markdown'
#
#   # Parse Markdown content
#   document = Ceradoc::Markdown.parse("# Title\n\nContent")
#
#   # Serialize back to Markdown
#   output = Ceradoc::Markdown.serialize(document)

require 'parsanol'
require 'parsanol/convenience'
require 'lutaml/model'

# Ceradoc document transformation library.
module Ceradoc
  # Markdown document model, parser, and serializer.
  module Markdown
    # Error classes
    autoload :Errors, 'ceradoc/markdown/errors'

    # Autoload model classes
    autoload :Base, 'ceradoc/markdown/model/base'
    autoload :Document, 'ceradoc/markdown/model/document'
    autoload :Heading, 'ceradoc/markdown/model/heading'
    autoload :Paragraph, 'ceradoc/markdown/model/paragraph'
    autoload :Text, 'ceradoc/markdown/model/text'

    # Registration side effect: loading registers rules into Ceradoc::Lint.registry.
    autoload :Lint, 'ceradoc/markdown/lint'
    autoload :List, 'ceradoc/markdown/model/list'
    autoload :ListItem, 'ceradoc/markdown/model/list_item'
    autoload :CodeBlock, 'ceradoc/markdown/model/code_block'
    autoload :Blockquote, 'ceradoc/markdown/model/blockquote'
    autoload :Link, 'ceradoc/markdown/model/link'
    autoload :Image, 'ceradoc/markdown/model/image'
    autoload :HorizontalRule, 'ceradoc/markdown/model/horizontal_rule'
    autoload :Table, 'ceradoc/markdown/model/table'
    autoload :Emphasis, 'ceradoc/markdown/model/emphasis'
    autoload :Strong, 'ceradoc/markdown/model/strong'
    autoload :Code, 'ceradoc/markdown/model/code'
    autoload :DefinitionList, 'ceradoc/markdown/model/definition_list'
    autoload :DefinitionTerm, 'ceradoc/markdown/model/definition_term'
    autoload :DefinitionItem, 'ceradoc/markdown/model/definition_item'
    autoload :Footnote, 'ceradoc/markdown/model/footnote'
    autoload :FootnoteReference, 'ceradoc/markdown/model/footnote_reference'
    autoload :Abbreviation, 'ceradoc/markdown/model/abbreviation'
    autoload :AttributeList, 'ceradoc/markdown/model/attribute_list'
    autoload :Math, 'ceradoc/markdown/model/math'
    autoload :Extension, 'ceradoc/markdown/model/extension'
    autoload :Strikethrough, 'ceradoc/markdown/model/strikethrough'
    autoload :Highlight, 'ceradoc/markdown/model/highlight'
    autoload :Subscript, 'ceradoc/markdown/model/subscript'
    autoload :Superscript, 'ceradoc/markdown/model/superscript'
    autoload :Underline, 'ceradoc/markdown/model/underline'
    autoload :CrossReference, 'ceradoc/markdown/model/cross_reference'
    autoload :NamedValue, 'ceradoc/markdown/model/named_value'
    autoload :Comment, 'ceradoc/markdown/model/comment'
    autoload :Admonition, 'ceradoc/markdown/model/admonition'
    autoload :ExampleBlock, 'ceradoc/markdown/model/example_block'
    autoload :OpenBlock, 'ceradoc/markdown/model/open_block'
    autoload :Sidebar, 'ceradoc/markdown/model/sidebar'
    autoload :Verse, 'ceradoc/markdown/model/verse'
    autoload :Pass, 'ceradoc/markdown/model/pass'
    autoload :Literal, 'ceradoc/markdown/model/literal'
    autoload :HardLineBreak, 'ceradoc/markdown/model/hard_line_break'

    # Declarative schemas + generated classes; hand-written behavior modules
    autoload :Schema, 'ceradoc/markdown/schema'
    autoload :Behaviors, 'ceradoc/markdown/behaviors'

    # Serializer
    autoload :Serializer, 'ceradoc/markdown/serializer'

    # TOC Generator
    autoload :TocGenerator, 'ceradoc/markdown/toc_generator'

    # Transformer (AST to Model)
    autoload :Transformer, 'ceradoc/markdown/transformer'

    # CoreModel transformers
    module Transform
      autoload :TextExtraction, 'ceradoc/markdown/transform/text_extraction'
      autoload :ToCoreModel, 'ceradoc/markdown/transform/to_core_model'
      autoload :FromCoreModel, 'ceradoc/markdown/transform/from_core_model'
    end

    # Parser module namespace
    module Parser
      autoload :AttributeLists, 'ceradoc/markdown/parser/attribute_lists'
      autoload :BlockParser, 'ceradoc/markdown/parser/block_parser'
      autoload :InlineParser, 'ceradoc/markdown/parser/inline_parser'
      autoload :ParsanolAtoms, 'ceradoc/markdown/parser/parsanol_atoms'
      autoload :HTML_ENTITIES, 'ceradoc/markdown/parser/html_entities'
      autoload :AstProcessor, 'ceradoc/markdown/parser/ast_processor'
      autoload :FrontmatterParser, 'ceradoc/markdown/parser/frontmatter_parser'
      autoload :Grammar, 'ceradoc/markdown/parser/grammar'
    end

    # Shared parser utilities
    autoload :ParserUtil, 'ceradoc/markdown/parser_util'
    autoload :Bindings, 'ceradoc/markdown/bindings'

    class << self
      # Parse Markdown content into a Document model
      #
      # @param content [String] The Markdown content to parse
      # @param options [Hash] Parsing options
      # @option options [Ceradoc::BindingInflater] :bindings inflate bound
      #   rules straight to model classes (see Bindings); unbound rules take
      #   the regular Transformer path
      # @return [Ceradoc::Markdown::Document] The parsed document model
      def parse(content, options = {})
        split = Parser::FrontmatterParser.call(content)
        ast = Parser::BlockParser.new.parse(split.body)
        doc = Transformer.with_bindings(options[:bindings]) { Transformer.transform_document(ast) }
        doc.frontmatter = split.frontmatter if split.frontmatter?
        doc
      end

      # Parse raw AST (for debugging)
      #
      # @param content [String] The Markdown content to parse
      # @return [Array] The raw AST
      def parse_ast(content)
        Parser::BlockParser.new.parse(content)
      end

      # Parse Markdown from a file
      #
      # @param filename [String] Path to the Markdown file
      # @param options [Hash] Parsing options (see #parse)
      # @return [Array] The parsed AST
      def from_file(filename, **)
        content = File.read(filename)
        parse(content, **)
      end

      # Parse inline Markdown content
      #
      # @param content [String] The inline Markdown content to parse
      # @return [Array] The parsed inline elements
      def parse_inline(content)
        Parser::InlineParser.new.parse(content)
      end

      # Serialize a document model to Markdown string
      #
      # @param document [Ceradoc::Markdown::Document] The document to serialize
      # @param options [Hash] Serialization options
      # @return [String] The Markdown output
      def serialize(document, options = {})
        document = Transform::FromCoreModel.transform(document) if document.is_a?(Ceradoc::CoreModel::Base)
        Serializer.serialize(document, options)
      end

      # Markdown preserves unresolved include edges as HTML comments
      # (Transform::FromCoreModel#transform_include) — lossy formatting,
      # but never silent content loss.
      def preserves_unresolved_includes?
        true
      end

      # Check if this format can transform the given model to CoreModel
      #
      # @param model [Object] The model to check
      # @return [Boolean] true if this format handles the model type
      def handles_model?(model)
        model.is_a?(Ceradoc::Markdown::Base)
      end

      # Transform Markdown model to CoreModel
      #
      # @param document [Ceradoc::Markdown::Document] The Markdown document
      # @return [Ceradoc::CoreModel::StructuralElement] The CoreModel document
      def to_core_model(document)
        Transform::ToCoreModel.transform(document)
      end
      alias to_core to_core_model

      # Parse and transform to CoreModel in one step
      #
      # @param content [String] The Markdown content
      # @return [Ceradoc::CoreModel::StructuralElement] The CoreModel document
      def parse_to_core(content)
        doc = parse(content)
        to_core_model(doc)
      end

      # Transform CoreModel to Markdown model
      #
      # @param core_document [Ceradoc::CoreModel::StructuralElement] The CoreModel document
      # @return [Ceradoc::Markdown::Document] The Markdown document
      def from_core_model(core_document)
        Transform::FromCoreModel.transform(core_document)
      end
    end
  end

  # Opt-in: replace the hand-written model classes with the ones generated
  # from ceradoc-markdown/schemas/*.yml (see Ceradoc::Markdown::Schema).
  Markdown::Schema.install! if ENV['CERADOC_MARKDOWN_GENERATED'] == '1'

  # Register the Markdown format with Ceradoc
  register_format(:markdown, Markdown,
                  aliases: %w[md markdown mdown mkd],
                  extensions: %w[.md .markdown .mdown .mkd])
end
