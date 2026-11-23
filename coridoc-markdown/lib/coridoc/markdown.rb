# frozen_string_literal: true

# coridoc-markdown - Markdown document model, parser, and serializer
#
# This gem provides Markdown support for the Coridoc document processing library.
# It includes:
# - Markdown Document Model (Coridoc::Markdown::*)
# - Markdown Parser (CommonMark-compliant, Parsanol-based)
# - Markdown Serializer (round-trip capable)
# - Kramdown extensions support (IAL, ALD, math, TOC)
#
# @example Basic usage
#   require 'coridoc/markdown'
#
#   # Parse Markdown content
#   document = Coridoc::Markdown.parse("# Title\n\nContent")
#
#   # Serialize back to Markdown
#   output = Coridoc::Markdown.serialize(document)

require 'parsanol'
require 'parsanol/convenience'
require 'lutaml/model'

# Coridoc document transformation library.
module Coridoc
  # Markdown document model, parser, and serializer.
  module Markdown
    # Error classes
    autoload :Errors, 'coridoc/markdown/errors'

    # Autoload model classes
    autoload :Base, 'coridoc/markdown/model/base'
    autoload :Document, 'coridoc/markdown/model/document'
    autoload :Heading, 'coridoc/markdown/model/heading'
    autoload :Paragraph, 'coridoc/markdown/model/paragraph'
    autoload :Text, 'coridoc/markdown/model/text'

    # Registration side effect: loading registers rules into Coridoc::Lint.registry.
    autoload :Lint, 'coridoc/markdown/lint'
    autoload :List, 'coridoc/markdown/model/list'
    autoload :ListItem, 'coridoc/markdown/model/list_item'
    autoload :CodeBlock, 'coridoc/markdown/model/code_block'
    autoload :Blockquote, 'coridoc/markdown/model/blockquote'
    autoload :Link, 'coridoc/markdown/model/link'
    autoload :Image, 'coridoc/markdown/model/image'
    autoload :HorizontalRule, 'coridoc/markdown/model/horizontal_rule'
    autoload :Table, 'coridoc/markdown/model/table'
    autoload :Emphasis, 'coridoc/markdown/model/emphasis'
    autoload :Strong, 'coridoc/markdown/model/strong'
    autoload :Code, 'coridoc/markdown/model/code'
    autoload :DefinitionList, 'coridoc/markdown/model/definition_list'
    autoload :DefinitionTerm, 'coridoc/markdown/model/definition_term'
    autoload :DefinitionItem, 'coridoc/markdown/model/definition_item'
    autoload :Footnote, 'coridoc/markdown/model/footnote'
    autoload :FootnoteReference, 'coridoc/markdown/model/footnote_reference'
    autoload :Abbreviation, 'coridoc/markdown/model/abbreviation'
    autoload :AttributeList, 'coridoc/markdown/model/attribute_list'
    autoload :Math, 'coridoc/markdown/model/math'
    autoload :Extension, 'coridoc/markdown/model/extension'
    autoload :Strikethrough, 'coridoc/markdown/model/strikethrough'
    autoload :Highlight, 'coridoc/markdown/model/highlight'
    autoload :Subscript, 'coridoc/markdown/model/subscript'
    autoload :Superscript, 'coridoc/markdown/model/superscript'
    autoload :Underline, 'coridoc/markdown/model/underline'
    autoload :CrossReference, 'coridoc/markdown/model/cross_reference'
    autoload :NamedValue, 'coridoc/markdown/model/named_value'
    autoload :Comment, 'coridoc/markdown/model/comment'
    autoload :Admonition, 'coridoc/markdown/model/admonition'
    autoload :ExampleBlock, 'coridoc/markdown/model/example_block'
    autoload :OpenBlock, 'coridoc/markdown/model/open_block'
    autoload :Sidebar, 'coridoc/markdown/model/sidebar'
    autoload :Verse, 'coridoc/markdown/model/verse'
    autoload :Pass, 'coridoc/markdown/model/pass'
    autoload :Literal, 'coridoc/markdown/model/literal'
    autoload :HardLineBreak, 'coridoc/markdown/model/hard_line_break'

    # Declarative schemas + generated classes; hand-written behavior modules
    autoload :Schema, 'coridoc/markdown/schema'
    autoload :Behaviors, 'coridoc/markdown/behaviors'

    # Serializer
    autoload :Serializer, 'coridoc/markdown/serializer'

    # TOC Generator
    autoload :TocGenerator, 'coridoc/markdown/toc_generator'

    # Transformer (AST to Model)
    autoload :Transformer, 'coridoc/markdown/transformer'

    # CoreModel transformers
    module Transform
      autoload :TextExtraction, 'coridoc/markdown/transform/text_extraction'
      autoload :ToCoreModel, 'coridoc/markdown/transform/to_core_model'
      autoload :FromCoreModel, 'coridoc/markdown/transform/from_core_model'
    end

    # Parser module namespace
    module Parser
      autoload :AttributeLists, 'coridoc/markdown/parser/attribute_lists'
      autoload :BlockParser, 'coridoc/markdown/parser/block_parser'
      autoload :InlineParser, 'coridoc/markdown/parser/inline_parser'
      autoload :ParsanolAtoms, 'coridoc/markdown/parser/parsanol_atoms'
      autoload :HTML_ENTITIES, 'coridoc/markdown/parser/html_entities'
      autoload :AstProcessor, 'coridoc/markdown/parser/ast_processor'
      autoload :FrontmatterParser, 'coridoc/markdown/parser/frontmatter_parser'
      autoload :Grammar, 'coridoc/markdown/parser/grammar'
    end

    # Shared parser utilities
    autoload :ParserUtil, 'coridoc/markdown/parser_util'
    autoload :Bindings, 'coridoc/markdown/bindings'

    class << self
      # Parse Markdown content into a Document model
      #
      # @param content [String] The Markdown content to parse
      # @param options [Hash] Parsing options
      # @option options [Coridoc::BindingInflater] :bindings inflate bound
      #   rules straight to model classes (see Bindings); unbound rules take
      #   the regular Transformer path
      # @return [Coridoc::Markdown::Document] The parsed document model
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
      # @param document [Coridoc::Markdown::Document] The document to serialize
      # @param options [Hash] Serialization options
      # @return [String] The Markdown output
      def serialize(document, options = {})
        document = Transform::FromCoreModel.transform(document) if document.is_a?(Coridoc::CoreModel::Base)
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
        model.is_a?(Coridoc::Markdown::Base)
      end

      # Transform Markdown model to CoreModel
      #
      # @param document [Coridoc::Markdown::Document] The Markdown document
      # @return [Coridoc::CoreModel::StructuralElement] The CoreModel document
      def to_core_model(document)
        Transform::ToCoreModel.transform(document)
      end
      alias to_core to_core_model

      # Parse and transform to CoreModel in one step
      #
      # @param content [String] The Markdown content
      # @return [Coridoc::CoreModel::StructuralElement] The CoreModel document
      def parse_to_core(content)
        doc = parse(content)
        to_core_model(doc)
      end

      # Transform CoreModel to Markdown model
      #
      # @param core_document [Coridoc::CoreModel::StructuralElement] The CoreModel document
      # @return [Coridoc::Markdown::Document] The Markdown document
      def from_core_model(core_document)
        Transform::FromCoreModel.transform(core_document)
      end
    end
  end

  # Opt-in: replace the hand-written model classes with the ones generated
  # from coridoc-markdown/schemas/*.yml (see Coridoc::Markdown::Schema).
  Markdown::Schema.install! if ENV['CORIDOC_MARKDOWN_GENERATED'] == '1'

  # Register the Markdown format with Coridoc
  register_format(:markdown, Markdown,
                  aliases: %w[md markdown mdown mkd],
                  extensions: %w[.md .markdown .mdown .mkd])
end
