# frozen_string_literal: true

require 'parsanol'
require 'lutaml/model'
require 'ceradoc'

module Ceradoc
  # Utility module autoload
  autoload :Util, "#{__dir__}/util"

  module AsciiDoc
    # Base error class for AsciiDoc gem, inheriting from Ceradoc::Error
    # for consistent error handling across all gems
    class Error < Ceradoc::Error; end
  end
end

# Autoload version and parse error
require_relative 'asciidoc/version'

module Ceradoc
  module AsciiDoc
    autoload :ParseError, "#{__dir__}/asciidoc/parse_error"
  end
end

# Autoload main components (lazy loading)
module Ceradoc
  module AsciiDoc
    autoload :DelimiterMapping, "#{__dir__}/asciidoc/delimiter_mapping"
    autoload :TypographicQuotes, "#{__dir__}/asciidoc/typographic_quotes"
    autoload :Model, "#{__dir__}/asciidoc/model"
    autoload :Parser, "#{__dir__}/asciidoc/parser"
    autoload :Bindings, "#{__dir__}/asciidoc/bindings"
    autoload :Transformer, "#{__dir__}/asciidoc/transformer"
    # Registration side effect: loading registers rules into Ceradoc::Lint.registry.
    autoload :Lint, "#{__dir__}/asciidoc/lint"
    autoload :Formatter, "#{__dir__}/asciidoc/formatter"
    autoload :Serializer, "#{__dir__}/asciidoc/serializer"
    autoload :Transform, "#{__dir__}/asciidoc/transform"
    autoload :Builder, "#{__dir__}/asciidoc/builder"
  end
end

# Now define the module methods after all dependencies are loaded
module Ceradoc
  module AsciiDoc
    class << self
      # Parse AsciiDoc text and return an AsciiDoc document model
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Ceradoc::AsciiDoc::Model::Document] Parsed document model
      def parse(text)
        split = Parser::FrontmatterParser.call(text)
        ast = Ceradoc::AsciiDoc::Parser::Base.parse(split.body)
        doc = Ceradoc::AsciiDoc::Transformer.transform(ast)
        doc.frontmatter = split.frontmatter if split.frontmatter?
        doc
      end

      # Parse AsciiDoc text and convert to CoreModel
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Ceradoc::CoreModel::Document] CoreModel document
      def parse_to_core(text)
        doc = parse(text)
        Ceradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
      end

      # Check if this format can transform the given model to CoreModel
      #
      # @param model [Object] The model to check
      # @return [Boolean] true if this format handles the model type
      def handles_model?(model)
        model.is_a?(Ceradoc::AsciiDoc::Model::Base)
      end

      # Transform an AsciiDoc model to CoreModel
      #
      # @param document [Ceradoc::AsciiDoc::Model::Base] AsciiDoc document model
      # @return [Ceradoc::CoreModel::Base] CoreModel
      def to_core(document)
        Transform::ToCoreModel.transform(document)
      end

      # Canonical-format AsciiDoc text (#110): parse to the model
      # tree, serialize, and normalize inter-block whitespace.
      #
      # @param text [String] AsciiDoc content
      # @return [String] canonically formatted AsciiDoc
      def format(text)
        Formatter.call(text)
      end

      # Serialize a document model to AsciiDoc string
      #
      # @param document [Ceradoc::AsciiDoc::Model::Document, Ceradoc::CoreModel::Base]
      #   Document model to serialize
      # @param options [Hash] Serialization options forwarded to the serializer
      # @return [String] AsciiDoc representation
      def serialize(document, options = {})
        case document
        when Ceradoc::CoreModel::Base
          # Convert CoreModel to AsciiDoc model first
          adoc_model = Ceradoc::AsciiDoc::Transform::FromCoreModel.transform(document)
          Serializer.serialize(adoc_model, options)
        else
          document.to_adoc
        end
      end

      # AsciiDoc round-trips include:: directives natively — graph-mode
      # documents serialize losslessly, no hydration required.
      def preserves_unresolved_includes?
        true
      end
    end

    # Backward-compatible aliases for model classes
    # These allow tests and legacy code to use Ceradoc::AsciiDoc::Document
    # instead of Ceradoc::AsciiDoc::Model::Document
    Base = Model::Base
    Document = Model::Document
    Section = Model::Section
    Paragraph = Model::Paragraph
    TextElement = Model::TextElement
    Title = Model::Title
    Header = Model::Header
    Admonition = Model::Admonition
    Table = Model::Table
    TableRow = Model::TableRow
    TableCell = Model::TableCell
    Term = Model::Term
    Break = Model::Break
    Audio = Model::Audio
    Video = Model::Video
    Bibliography = Model::Bibliography
    BibliographyEntry = Model::BibliographyEntry
    CommentBlock = Model::CommentBlock
    CommentLine = Model::CommentLine
    LineBreak = Model::LineBreak
    Include = Model::Include
    Attribute = Model::Attribute
    AttributeList = Model::AttributeList
    Author = Model::Author
    Revision = Model::Revision
    NamedAttribute = Model::NamedAttribute
    ContentList = Model::ContentList
    Tag = Model::Tag
    Highlight = Model::Highlight
    DocumentAttributes = Model::DocumentAttributes

    # Namespace aliases for nested modules
    Inline = Model::Inline
    Block = Model::Block
    List = Model::List
    Image = Model::Image

    # Module aliases for mixins
    Anchorable = Model::Anchorable
    Attached = Model::Attached
    Spacing = Model::Spacing
  end
end

# Register the AsciiDoc format with Ceradoc after module is fully defined
# Use conditional registration to handle load order issues
Ceradoc.register_format(:asciidoc, Ceradoc::AsciiDoc,
                        aliases: %w[adoc asciidoc],
                        extensions: %w[.adoc .asciidoc])

# Backward-compatibility: Ceradoc::Model is now Ceradoc::AsciiDoc::Model
# This alias is provided for legacy code that hasn't been updated
Ceradoc::Model = Ceradoc::AsciiDoc::Model unless defined?(Ceradoc::Model)

# Reference materializers for format: :asciidoc. Required (not autoloaded)
# because registration is a load-time side effect, like register_format.
require 'ceradoc/asciidoc/reference_materializers'
