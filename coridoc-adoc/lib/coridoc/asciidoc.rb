# frozen_string_literal: true

require 'parsanol'
require 'lutaml/model'
require 'coridoc'

module Coridoc
  # Utility module autoload
  autoload :Util, "#{__dir__}/util"

  module AsciiDoc
    # Base error class for AsciiDoc gem, inheriting from Coridoc::Error
    # for consistent error handling across all gems
    class Error < Coridoc::Error; end
  end
end

# Autoload version and parse error
require_relative 'asciidoc/version'

module Coridoc
  module AsciiDoc
    autoload :ParseError, "#{__dir__}/asciidoc/parse_error"
  end
end

# Autoload main components (lazy loading)
module Coridoc
  module AsciiDoc
    autoload :DelimiterMapping, "#{__dir__}/asciidoc/delimiter_mapping"
    autoload :TypographicQuotes, "#{__dir__}/asciidoc/typographic_quotes"
    autoload :Model, "#{__dir__}/asciidoc/model"
    autoload :Parser, "#{__dir__}/asciidoc/parser"
    autoload :Bindings, "#{__dir__}/asciidoc/bindings"
    autoload :Transformer, "#{__dir__}/asciidoc/transformer"
    # Registration side effect: loading registers rules into Coridoc::Lint.registry.
    autoload :Lint, "#{__dir__}/asciidoc/lint"
    autoload :Formatter, "#{__dir__}/asciidoc/formatter"
    autoload :Serializer, "#{__dir__}/asciidoc/serializer"
    autoload :Transform, "#{__dir__}/asciidoc/transform"
    autoload :Builder, "#{__dir__}/asciidoc/builder"
  end
end

# Now define the module methods after all dependencies are loaded
module Coridoc
  module AsciiDoc
    class << self
      # Parse AsciiDoc text and return an AsciiDoc document model
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Coridoc::AsciiDoc::Model::Document] Parsed document model
      def parse(text)
        split = Parser::FrontmatterParser.call(text)
        ast = Coridoc::AsciiDoc::Parser::Base.parse(split.body)
        doc = Coridoc::AsciiDoc::Transformer.transform(ast)
        doc.frontmatter = split.frontmatter if split.frontmatter?
        doc
      end

      # Parse AsciiDoc text and convert to CoreModel
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Coridoc::CoreModel::Document] CoreModel document
      def parse_to_core(text)
        doc = parse(text)
        Coridoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
      end

      # Check if this format can transform the given model to CoreModel
      #
      # @param model [Object] The model to check
      # @return [Boolean] true if this format handles the model type
      def handles_model?(model)
        model.is_a?(Coridoc::AsciiDoc::Model::Base)
      end

      # Transform an AsciiDoc model to CoreModel
      #
      # @param document [Coridoc::AsciiDoc::Model::Base] AsciiDoc document model
      # @return [Coridoc::CoreModel::Base] CoreModel
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
      # @param document [Coridoc::AsciiDoc::Model::Document, Coridoc::CoreModel::Base]
      #   Document model to serialize
      # @return [String] AsciiDoc representation
      def serialize(document)
        case document
        when Coridoc::CoreModel::Base
          # Convert CoreModel to AsciiDoc model first
          adoc_model = Coridoc::AsciiDoc::Transform::FromCoreModel.transform(document)
          adoc_model.to_adoc
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
    # These allow tests and legacy code to use Coridoc::AsciiDoc::Document
    # instead of Coridoc::AsciiDoc::Model::Document
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

# Register the AsciiDoc format with Coridoc after module is fully defined
# Use conditional registration to handle load order issues
Coridoc.register_format(:asciidoc, Coridoc::AsciiDoc,
                        aliases: %w[adoc asciidoc],
                        extensions: %w[.adoc .asciidoc])

# Backward-compatibility: Coridoc::Model is now Coridoc::AsciiDoc::Model
# This alias is provided for legacy code that hasn't been updated
Coridoc::Model = Coridoc::AsciiDoc::Model unless defined?(Coridoc::Model)

# Reference materializers for format: :asciidoc. Required (not autoloaded)
# because registration is a load-time side effect, like register_format.
require 'coridoc/asciidoc/reference_materializers'
