# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      CONVERTERS = {
        Base: 'ceradoc/html/converters/base',
        Markup: 'ceradoc/html/converters/markup',
        A: 'ceradoc/html/converters/a',
        Aside: 'ceradoc/html/converters/aside',
        Audio: 'ceradoc/html/converters/audio',
        Blockquote: 'ceradoc/html/converters/blockquote',
        Br: 'ceradoc/html/converters/br',
        Bypass: 'ceradoc/html/converters/bypass',
        Code: 'ceradoc/html/converters/code',
        Div: 'ceradoc/html/converters/div',
        Dl: 'ceradoc/html/converters/dl',
        Skip: 'ceradoc/html/converters/drop',
        Em: 'ceradoc/html/converters/em',
        Figure: 'ceradoc/html/converters/figure',
        H: 'ceradoc/html/converters/h',
        Head: 'ceradoc/html/converters/head',
        Hr: 'ceradoc/html/converters/hr',
        Img: 'ceradoc/html/converters/img',
        Li: 'ceradoc/html/converters/li',
        Mark: 'ceradoc/html/converters/mark',
        Math: 'ceradoc/html/converters/math',
        MediaBase: 'ceradoc/html/converters/media_base',
        Ol: 'ceradoc/html/converters/ol',
        P: 'ceradoc/html/converters/p',
        PassThrough: 'ceradoc/html/converters/pass_through',
        PositionalFormatting: 'ceradoc/html/converters/positional_formatting',
        Pre: 'ceradoc/html/converters/pre',
        Q: 'ceradoc/html/converters/q',
        Strong: 'ceradoc/html/converters/strong',
        Sup: 'ceradoc/html/converters/sup',
        Sub: 'ceradoc/html/converters/sub',
        Table: 'ceradoc/html/converters/table',
        Td: 'ceradoc/html/converters/td',
        Text: 'ceradoc/html/converters/text',
        Tr: 'ceradoc/html/converters/tr',
        Video: 'ceradoc/html/converters/video'
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

      def self.process_ceradoc(node, state)
        node = node.to_a if node.is_a? Leptris::XML::NodeSet
        return node.map { |i| process_ceradoc(i, state) } if node.is_a? Array

        plugins = state[:plugin_instances] || {}
        process = proc { lookup(node.name).to_ceradoc(node, state) }
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
                'for Ceradoc::Html.input_config.unknown_tags'
        end
      end
    end
  end
end
