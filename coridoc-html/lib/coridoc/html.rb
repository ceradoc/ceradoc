# frozen_string_literal: true

module Coridoc
  module Html
    HTML_EXTENSIONS = %w[.html .htm].freeze

    module FormatDetection
      def html_extension?(filename)
        HTML_EXTENSIONS.any? { |ext| filename.downcase.end_with?(ext) }
      end
    end
  end
end

module Coridoc
  module Html
    autoload :InputConfig, 'coridoc/html/input_config'
    autoload :Cleaner, 'coridoc/html/cleaner'
    autoload :Errors, 'coridoc/html/errors'
    autoload :Plugin, 'coridoc/html/plugin'
    autoload :Postprocessor, 'coridoc/html/postprocessor'
    autoload :Converters, 'coridoc/html/converters'
    autoload :HtmlConverter, 'coridoc/html/html_converter'
    # Registration side effect: loading registers rules into Coridoc::Lint.registry.
    autoload :Lint, 'coridoc/html/lint'

    def self.input_config
      @input_config ||= InputConfig.new
      yield @input_config if block_given?
      @input_config
    end

    def self.reset_input_config!
      @input_config = nil
    end

    def self.cleaner
      @cleaner ||= Cleaner.new
    end

    def self.to_coridoc(html, options = {})
      HtmlConverter.to_core_model(html, options)
    end
  end
end

module Coridoc
  module Html
    # Autoload HTML components
    autoload :Config, 'coridoc/html/config'
    autoload :AssetResolver, 'coridoc/html/asset_resolver'
    autoload :TagMapping, 'coridoc/html/tag_mapping'
    autoload :Escape, 'coridoc/html/escape'
    autoload :SectionNumberable, 'coridoc/html/section_numberable'
    autoload :TemplateCaching, 'coridoc/html/template_caching'
    autoload :TitleText, 'coridoc/html/title_text'

    # Drop layer — self-registering drops loaded via parent namespace file
    require_relative 'html/drop'

    # FrontmatterBlock -> <meta> tag mapping (HTML-specific concern)
    autoload :FrontmatterMeta, 'coridoc/html/frontmatter_meta'

    # Autoload HTML output converters
    autoload :ConverterBase, 'coridoc/html/converter_base'
    autoload :Static, 'coridoc/html/static'
    autoload :Spa, 'coridoc/html/spa'
    autoload :TocBuilder, 'coridoc/html/toc_builder'

    # Theme system
    autoload :Theme, 'coridoc/html/theme'
    autoload :TemplateLocator, 'coridoc/html/template_locator'
    autoload :TemplateConfig, 'coridoc/html/template_config'
    # Side-effect: registers Liquid filters on load
    require_relative 'html/template_helpers'
    autoload :Renderer, 'coridoc/html/renderer'
    autoload :LayoutRenderer, 'coridoc/html/layout_renderer'
    autoload :Builder, 'coridoc/html/builder'
    autoload :RenderOptions, 'coridoc/html/render_options'
    autoload :TocSerializer, 'coridoc/html/toc_serializer'

    # CoreModel transformers
    module Transform
      autoload :ToCoreModel, 'coridoc/html/transform/to_core_model'
      autoload :FromCoreModel, 'coridoc/html/transform/from_core_model'
    end

    # Validate that input is a CoreModel type
    #
    # @param document [Object] Document to validate
    # @raise [ArgumentError] If document is not a CoreModel type
    # @return [Object] The validated document
    def self.validate_core_model!(document)
      return document if document.nil?

      unless document.is_a?(Coridoc::CoreModel::Base)
        raise ArgumentError,
              'coridoc-html only accepts CoreModel types. ' \
              "Got: #{document.class}. " \
              'Transform your document to CoreModel before passing to HTML conversion.'
      end

      document
    end

    # Parse HTML content and return CoreModel elements (may be an Array)
    def self.parse(html, options = {})
      HtmlConverter.to_core_model(html, options)
    end

    # Parse HTML content directly into a CoreModel document
    #
    # Unlike #parse which returns an Array of CoreModel elements,
    # this wraps the result into a top-level DocumentElement document
    # suitable for use with Coridoc.serialize and other CoreModel pipelines.
    #
    # @param html [String] HTML content
    # @param options [Hash] Parse options
    # @return [Coridoc::CoreModel::DocumentElement] CoreModel document
    def self.parse_to_core(html, options = {})
      elements = parse(html, options)

      return elements if elements.is_a?(Coridoc::CoreModel::Base)

      # Extract document title from the first heading element
      title = nil
      children = elements
      if elements.is_a?(Array) && !elements.empty?
        first = elements.first
        if first.is_a?(Coridoc::CoreModel::StructuralElement) &&
           first.section? && first.level == 1
          title = first.title
          children = first.children + elements[1..]
        end
      end

      Coridoc::CoreModel::DocumentElement.new(
        title: title,
        children: Array(children)
      )
    end

    # Parse HTML file
    def self.from_file(filename, **)
      content = File.read(filename)
      parse(content, **)
    end

    # Serialize CoreModel document to HTML
    #
    # Uses the unified Liquid template renderer.
    #
    # @param document [Coridoc::CoreModel::Base] CoreModel document to serialize
    # @param options [Hash] Output options
    # @return [String] HTML output
    def self.serialize(document, options = {})
      validate_core_model!(document)

      layout = options.delete(:layout) || :static
      renderer = Renderer.new(template_dirs: options.delete(:template_dirs))
      renderer.render_html5(document, layout: layout, **options)
    end

    # Serialize CoreModel document to static HTML
    #
    # Uses the classic theme renderer for traditional HTML output.
    #
    # @param document [Coridoc::CoreModel::Base] CoreModel document to serialize
    # @param config [Hash, Static::Configuration] Static converter configuration
    # @return [String] HTML output
    def self.serialize_static(document, config = {})
      Static.convert(document, config)
    end

    # Serialize CoreModel document to SPA HTML
    #
    # Uses the modern theme renderer for Vue.js + Tailwind output.
    #
    # @param document [Coridoc::CoreModel::Base] CoreModel document to serialize
    # @param config [Hash, Spa::Configuration] SPA converter configuration
    # @return [String] HTML output
    def self.serialize_spa(document, config = {})
      Spa.convert(document, config)
    end

    # Serialize CoreModel document to HTML with specified format
    #
    # @param document [Coridoc::CoreModel::Base] CoreModel document to serialize
    # @param format [Symbol] Output format (:static, :spa, :classic)
    # @param options [Hash] Converter options
    # @return [String] HTML output
    def self.serialize_as(document, format, options = {})
      case format.to_sym
      when :static, :html_static, :classic
        serialize_static(document, options)
      when :spa, :html_spa, :modern
        serialize_spa(document, options)
      else
        raise ArgumentError, "Unknown output format: #{format}. " \
                             'Valid formats: :static, :spa'
      end
    end

    # Transform HTML model to CoreModel
    #
    # @param document [Object] HTML input model
    # @return [Coridoc::CoreModel::Base] CoreModel document
    def self.to_core_model(document)
      Transform::ToCoreModel.transform(document)
    end

    # Check if this format can transform the given model to CoreModel
    #
    # HTML uses Leptris::XML as its model layer. Accepts Leptris nodes
    # and CoreModel objects (pass-through).
    #
    # @param model [Object] The model to check
    # @return [Boolean] true if the model is a Leptris node or CoreModel
    def self.handles_model?(model)
      model.is_a?(Leptris::XML::Node) ||
        model.is_a?(Leptris::XML::Document) ||
        model.is_a?(Coridoc::CoreModel::Base)
    end

    def self.to_core(document)
      to_core_model(document)
    end

    # Transform CoreModel to HTML-ready structure
    #
    # @param core_document [Coridoc::CoreModel::Base] CoreModel document
    # @return [Object] HTML-ready structure
    def self.from_core_model(core_document)
      Transform::FromCoreModel.transform(core_document)
    end
  end
end

# Register after all module methods are defined
Coridoc.register_format(:html, Coridoc::Html,
                        aliases: %w[html htm],
                        extensions: %w[.html .htm])

# Reference materializers for format: :html. Required (not autoloaded)
# because registration is a load-time side effect, like register_format.
require 'coridoc/html/reference_materializers'
