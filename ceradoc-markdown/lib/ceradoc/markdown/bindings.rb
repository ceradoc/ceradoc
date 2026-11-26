# frozen_string_literal: true

module Ceradoc
  module Markdown
    # PARG bindings for the Markdown grammar: which raw-tree rules
    # inflate directly to schema-generated model classes through
    # Ceradoc::BindingInflater. A rule is bound by its exact capture-key
    # set. The stateful rules (an ALD definition registers in the
    # document's Scope, a standalone IAL resolves against it) are bound
    # too, through scoped hooks; Transformer holds no rule. This is the
    # only stage-1 to stage-2 path; no per-rule transformer remains.
    #
    # Every rule takes its attributes from the raw subtree through a
    # named hook (`via:`), because the attribute is computed (heading
    # level from the marker, text joined from lines, list items grouped)
    # rather than copied from a capture. The rules themselves — keys,
    # models, hooks, optional captures, scope — live as the
    # model-bindings table embedded in the compiled artifact
    # (grammar/ceradoc-markdown.bindings.yml is its sidecar source);
    # this module owns only the hook surface: the Hooks module and the
    # registries that resolve the table's model and hook names to Ruby,
    # plus the merge that builds the block and inline inflaters from
    # their table groups.
    #
    # The binding machinery proper (codegen-ed bindings, typed capture
    # assignment) is lutaml-model#1033. The table ships inside the
    # compiled artifact, so the inflater needs no side file at runtime.
    module Bindings
      Binding = Ceradoc::BindingInflater::Binding

      autoload :Captures, "#{__dir__}/bindings/captures"
      autoload :Scope, "#{__dir__}/bindings/scope"

      # Semantic steps: raw captures in, model attributes out. They read the
      # raw captures through Captures.
      module Hooks
        module_function

        # The active model class by short name: hand-written by default,
        # the schema-generated one under CERADOC_MARKDOWN_GENERATED=1.
        def model(name)
          Bindings.model(name)
        end

        # IAL attributes, set only when present (as Transformer does).
        def ial(attrs)
          return {} unless attrs.key?(:ial)

          parsed = Captures.parse_ial_content(attrs[:ial].to_s)
          {
            id: parsed[:id], classes: parsed[:classes],
            # parse_to_hash yields attributes as a plain hash; the model
            # layer carries them as NamedValue pairs.
            attributes: named_values(parsed[:attributes])
          }.compact
        end

        # parse_to_hash yields attributes as a plain hash; the model
        # layer carries them as NamedValue pairs.
        def named_values(hash)
          # Base must fully load before NamedValue: NamedValue < Base,
          # and loading NamedValue FIRST leaves base.rb resolving the
          # NamedValue autoload mid-cycle (NameError). Any other model
          # class pulls Base in cleanly first.
          Bindings.model('Text')
          hash.to_a.map do |key, value|
            Bindings.model('NamedValue').new(name: key.to_s, value: value.to_s)
          end
        end

        def heading(attrs)
          text = attrs.key?(:text) ? Captures.extract_text(attrs[:text]).strip : ''
          { level: Captures.heading_level(attrs[:heading]), text: text, **ial(attrs) }
        end

        def code_block(attrs)
          language = attrs.key?(:info) ? { language: attrs[:info].to_s.strip } : {}
          { **language, code: Captures.extract_code(attrs[:code_block]), **ial(attrs) }
        end

        def block_quote(attrs, scope)
          content = attrs[:block_quote]
          nodes = content.is_a?(Array) ? content : [content]
          text = nodes.map { |node| Transformer.transform_element(node, scope) }.compact.map do |child|
            child.is_a?(Base) && child.class.attributes.key?(:text) ? child.text : child.to_s
          end.join("\n")
          { content: text, **ial(attrs) }
        end

        # An ALD definition registers in the document scope and yields no block.
        def ald_definition(attrs, scope)
          scope.define(attrs[:ald_name].to_s, Captures.parse_ial_content(attrs[:ial].to_s))
          nil
        end

        # An IAL on its own line: a registered ALD's attribute list, else a fresh one.
        def ial_reference(attrs, scope)
          scope.resolve(attrs[:ial].to_s)
        end

        def paragraph(attrs)
          p = attrs[:p]
          { text: Captures.extract_text_from_p(p), children: inline_models(p), **ial(attrs) }
        end

        # A bare line that no other rule claimed is a paragraph.
        def line(attrs)
          { text: attrs[:ln].to_s }
        end

        def list(attrs)
          ordered = attrs.key?(:ol)
          list_attributes(attrs[ordered ? :ol : :ul], ordered: ordered)
        end

        def list_attributes(items, ordered:)
          items = [items] unless items.is_a?(Array)
          { ordered: ordered, items: items.map { |node| list_item(node.is_a?(Hash) ? node[:li] : node) } }
        end

        def list_item(item_node)
          text_parts = []
          children = []
          sublist = nil
          Captures.normalize_list_item_nodes(item_node).each do |node|
            if !node.is_a?(Hash)
              text_parts << node.to_s
            elsif node.key?(:p)
              text_parts << Captures.extract_text_from_p(node[:p])
              children.concat(inline_models(node[:p]))
            elsif node.key?(:ul)
              sublist = model('List').new(**list_attributes(node[:ul], ordered: false))
            elsif node.key?(:ol)
              sublist = model('List').new(**list_attributes(node[:ol], ordered: true))
            end
          end
          item = model('ListItem').new(text: text_parts.join(' ').strip, children: children)
          item.sublist = sublist if sublist
          item
        end

        # The parser yields terms and definitions as a flat sequence;
        # each definition belongs to the term before it.
        def definition_list(attrs)
          entries = []
          Array(attrs[:dl]).each do |node|
            next unless node.is_a?(Hash)

            if node.key?(:def_term)
              entries << [Captures.extract_text(node[:def_term]).strip, []]
            elsif node.key?(:def_content) && entries.any?
              entries.last.last << model('DefinitionItem').new(
                content: Captures.extract_text(node[:def_content]).strip
              )
            end
          end
          { items: entries.map { |text, definitions| model('DefinitionTerm').new(text: text, definitions: definitions) } }
        end

        def table(attrs)
          rows = Array(attrs[:table_body]).map do |node|
            Captures.extract_row_cells(node[:table_body_row][:row]).join(' | ')
          end
          { headers: Captures.extract_row_cells(attrs[:table_header][:row]), rows: rows }
        end

        def footnote(attrs)
          lines = [attrs[:fn_content]]
          lines += Array(attrs[:fn_content_continued]) if attrs[:fn_content_continued]
          content = lines.map { |line| Captures.extract_text(line) }.join("\n")
          { id: attrs[:fn_id].to_s, content: content.strip }
        end

        def abbreviation(attrs)
          { term: attrs[:abbr_term].to_s, definition: attrs[:abbr_def].to_s.strip }
        end

        def footnote_reference(attrs)
          { id: attrs[:fn_ref].to_s }
        end

        # `{extension: {ext_*}}` wraps the same captures the bare form has.
        def extension(attrs)
          node = attrs[:extension] || attrs
          opts = node[:ext_options]
          empty = !opts || (opts.is_a?(Array) && opts.empty?)
          { name: node[:ext_name].to_s,
            options: empty ? {} : Captures.parse_extension_options(opts.to_s),
            content: node[:ext_body]&.to_s }
        end

        def math(attrs)
          { content: Captures.extract_text(attrs[:math_content]), inline: false }
        end

        def strong(attrs)
          { text: Captures.flatten_inline_text(attrs[:strong]) }
        end

        def emphasis(attrs)
          { text: Captures.flatten_inline_text(attrs[:emph]) }
        end

        def code(attrs)
          { text: attrs[:code].to_s }
        end

        def link(attrs)
          node = attrs[:link]
          if node.is_a?(Hash)
            model('Link').new(text: node[:link_text].to_s, url: node[:link_url].to_s)
          else
            { content: node.to_s }
          end
        end

        def image(attrs)
          node = attrs[:image]
          if node.is_a?(Hash)
            model('Image').new(alt: node[:link_text].to_s, src: node[:link_url].to_s)
          else
            { content: node.to_s }
          end
        end

        def text(attrs)
          { content: attrs[:text].to_s }
        end

        # Inline models for a paragraph's raw lines, each parsed by the
        # InlineParser and inflated through the inline bindings.
        def inline_models(paragraph)
          lines = if paragraph.is_a?(Hash)
                    [paragraph[:ln]]
                  else
                    Array(paragraph).map { |l| l.is_a?(Hash) ? l[:ln] : l }
                  end
          lines.compact.flat_map.with_index do |line, index|
            models = Ceradoc::Markdown.parse_inline(line.to_s).flat_map { |node| inline_model(node) }
            index.zero? ? models : [model('Text').new(content: "\n"), *models]
          end
        end

        def inline_model(node)
          Bindings.inline_inflater.inflate(node) do |unbound|
            content = unbound.is_a?(Hash) ? Captures.flatten_inline_text([unbound]) : unbound.to_s
            model('Text').new(content: content)
          end
        end
      end

      # The table's registries: model names to classes (lazily resolved
      # through `model`, so CERADOC_MARKDOWN_GENERATED keeps switching
      # the classes) and hook names to callables. The artifact table
      # references both by name only.
      MODELS = ->(name) { Bindings.model(name) }

      HOOKS = {
        'heading' => Hooks.method(:heading),
        'code_block' => Hooks.method(:code_block),
        'block_quote' => Hooks.method(:block_quote),
        'paragraph' => Hooks.method(:paragraph),
        'line' => Hooks.method(:line),
        'list' => Hooks.method(:list),
        'definition_list' => Hooks.method(:definition_list),
        'table' => Hooks.method(:table),
        'footnote' => Hooks.method(:footnote),
        'abbreviation' => Hooks.method(:abbreviation),
        'footnote_reference' => Hooks.method(:footnote_reference),
        'extension' => Hooks.method(:extension),
        'math' => Hooks.method(:math),
        'text' => Hooks.method(:text),
        'ald_definition' => Hooks.method(:ald_definition),
        'ial_reference' => Hooks.method(:ial_reference),
        'strong' => Hooks.method(:strong),
        'emphasis' => Hooks.method(:emphasis),
        'code' => Hooks.method(:code),
        'link' => Hooks.method(:link),
        'image' => Hooks.method(:image)
      }.freeze

      class << self
        # The active model class by short name (Ceradoc::Markdown::Heading).
        # Hand-written by default; CERADOC_MARKDOWN_GENERATED=1 replaces the
        # constants with the schema-generated classes, so bound output
        # always matches what the rest of the gem dispatches on.
        def model(name)
          Ceradoc::Markdown.const_get(name, false)
        end

        # @return [Ceradoc::BindingInflater] the inflater for the bound
        #   block rules: the artifact table's `block` group plus the
        #   untagged rules shared with the inline grammar
        def inflater
          @inflater ||= table_inflater(groups: ['block'])
        end

        # @return [Ceradoc::BindingInflater] the inflater for inline nodes
        def inline_inflater
          @inline_inflater ||= table_inflater(groups: ['inline'])
        end

        private

        def table_inflater(groups:)
          Ceradoc::BindingInflater.from_table(
            Parser::Grammar.model_bindings, models: MODELS, hooks: HOOKS, groups: groups
          )
        end
      end
    end
  end
end
