# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      CONVERTERS = {
        Base: 'coridoc/html/converters/base',
        Markup: 'coridoc/html/converters/markup',
        A: 'coridoc/html/converters/a',
        Aside: 'coridoc/html/converters/aside',
        Audio: 'coridoc/html/converters/audio',
        Blockquote: 'coridoc/html/converters/blockquote',
        Br: 'coridoc/html/converters/br',
        Bypass: 'coridoc/html/converters/bypass',
        Code: 'coridoc/html/converters/code',
        Div: 'coridoc/html/converters/div',
        Dl: 'coridoc/html/converters/dl',
        Skip: 'coridoc/html/converters/drop',
        Em: 'coridoc/html/converters/em',
        Figure: 'coridoc/html/converters/figure',
        H: 'coridoc/html/converters/h',
        Head: 'coridoc/html/converters/head',
        Hr: 'coridoc/html/converters/hr',
        Img: 'coridoc/html/converters/img',
        Li: 'coridoc/html/converters/li',
        Mark: 'coridoc/html/converters/mark',
        Math: 'coridoc/html/converters/math',
        MediaBase: 'coridoc/html/converters/media_base',
        Ol: 'coridoc/html/converters/ol',
        P: 'coridoc/html/converters/p',
        PassThrough: 'coridoc/html/converters/pass_through',
        PositionalFormatting: 'coridoc/html/converters/positional_formatting',
        Pre: 'coridoc/html/converters/pre',
        Q: 'coridoc/html/converters/q',
        Strong: 'coridoc/html/converters/strong',
        Sup: 'coridoc/html/converters/sup',
        Sub: 'coridoc/html/converters/sub',
        Table: 'coridoc/html/converters/table',
        Td: 'coridoc/html/converters/td',
        Text: 'coridoc/html/converters/text',
        Tr: 'coridoc/html/converters/tr',
        Video: 'coridoc/html/converters/video'
      }.freeze
      private_constant :CONVERTERS

      CONVERTERS.each do |name, path|
        autoload name, path
      end

      @converters = {}
      @converters_loaded = false

      def self.register(tag_name, converter)
        @converters[tag_name.to_sym] = converter
      end

      def self.unregister(tag_name)
        @converters.delete(tag_name.to_sym)
      end

      def self.ensure_converters_loaded
        return if @converters_loaded

        @converters_loaded = true
        CONVERTERS.each_key { |name| const_get(name) }
      end

      def self.lookup(tag_name)
        ensure_converters_loaded
        @converters[tag_name.to_sym] || default_converter(tag_name)
      end

      def self.process_coridoc(node, state)
        node = node.to_a if node.is_a? Leptris::XML::NodeSet
        return node.map { |i| process_coridoc(i, state) } if node.is_a? Array

        plugins = state[:plugin_instances] || {}
        process = proc { lookup(node.name).to_coridoc(node, state) }
        plugins.each do |i|
          prev_process = process
          process = proc { i.html_tree_run_hooks(node, state, &prev_process) }
        end
        process.call(node, state)
      end

      def self.default_converter(tag_name)
        case Html.input_config.unknown_tags.to_sym
        when :pass_through
          PassThrough::INSTANCE
        when :drop
          Skip::INSTANCE
        when :bypass
          Bypass::INSTANCE
        when :raise
          raise Errors::UnknownTagError, "unknown tag: #{tag_name}"
        else
          raise Errors::InvalidConfigurationError,
                "unknown value #{Html.input_config.unknown_tags.inspect} " \
                'for Coridoc::Html.input_config.unknown_tags'
        end
      end
    end
  end
end
