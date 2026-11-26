# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    # PARG bindings for the AsciiDoc grammar (M3 of the parg-bindings
    # migration): raw-tree rules that inflate straight to model classes
    # through Ceradoc::BindingInflater. The rules live as the
    # model-bindings table embedded in the compiled artifact
    # (grammar/ceradoc-adoc.bindings.yml is its sidecar source) — this
    # module owns only the hook surface: the named hooks (`via:`) that
    # carry each rule's semantic step, and the registries that resolve
    # the table's model and hook names to Ruby. A hook that keeps
    # growing is a grammar-shape problem, not a hook problem.
    module Bindings
      autoload :DefinitionListTree, "#{__dir__}/bindings/definition_list_tree"
      autoload :StructureHooks, "#{__dir__}/bindings/structure_hooks"

      Binding = Ceradoc::BindingInflater::Binding

      # Named hooks: the ~20% of rules that are not pure
      # capture-to-attribute wiring.
      module Hooks
        module_function

        # Header: flatten the raw `{title:, author:, revision:}` capture
        # and inherit the id from a Title model when the header has none.
        def header(attributes)
          raw = attributes.fetch(:header)
          title = raw[:title]
          id = raw[:id]
          id = title.id if title.is_a?(Model::Title) && title.id && !id
          id = id.to_s unless id.nil?
          id = nil if id&.empty?

          { id:, title:, author: raw[:author], revision: raw[:revision] }
        end

        # Paragraph: raw `lines` become TextElements (same-line joins and
        # inline arrays are normalised by Transformer.lines_to_text_elements).
        def paragraph(attributes)
          raw = attributes.fetch(:paragraph)
          {
            content: Transformer.lines_to_text_elements(raw[:lines]),
            id: raw[:id],
            attributes: raw[:attribute_list],
            title: raw[:title]
          }
        end

        # List item: lines become TextElements (or the bare text), and a
        # raw `nested` array is wrapped into the list type its first
        # marker implies.
        def list_item(attributes)
          raw = attributes.fetch(:list_item)
          lines = raw[:lines]
          content = lines ? Transformer.lines_to_text_elements(lines) : raw[:text].to_s

          { content:, id: raw[:id], marker: raw[:marker], attached: raw[:attached],
            nested: nest_list_items(raw[:nested]), line_break: raw[:line_break] }
        end

        def nest_list_items(nested)
          return nested unless nested.is_a?(Array) && nested.any?

          if nested.all?(Model::List::Core)
            nested.first
          elsif nested.all?(Model::List::Item)
            ordered = nested.first.marker.to_s.lstrip.start_with?('.', '1', 'a', 'A', 'i', 'I')
            (ordered ? Model::List::Ordered : Model::List::Unordered).new(items: nested)
          else
            nested
          end
        end

        # `list:` wrapper node: the inner list passes through.
        def list(attributes)
          attributes.fetch(:list)
        end

        # Definition-list term: flatten to `{text:, id:, delimiter:}`.
        def dlist_term(attributes)
          term = attributes.fetch(:term)
          delimiter = attributes.fetch(:delimiter).to_s
          case term
          when Hash
            text = term[:text]
            text = text.content.to_s if text.is_a?(Model::TextElement)
            { text: text.to_s, id: term[:id]&.to_s, delimiter: }
          when Model::TextElement
            { text: term.content.to_s, id: term.id, delimiter: }
          else
            { text: term.to_s, id: nil, delimiter: }
          end
        end

        # Definition-list item: dd lines split on hard breaks, terms and
        # the item's id/delimiter taken from the flattened term hashes.
        def definition_list_item(attributes)
          raw = attributes.fetch(:item)
          data = raw.is_a?(Hash) ? raw : { terms: Array(raw), lines: [] }
          contents = Transformer.lines_to_text_elements(Transformer.split_lines_on_hard_break(data[:lines] || []))
          id = nil
          delimiter = '::'
          terms = Array(data[:terms]).map do |term|
            next term.to_s unless term.is_a?(Hash)

            id ||= term[:id].to_s if term[:id]
            delimiter = term[:delimiter].to_s if term[:delimiter]
            term[:text].to_s
          end

          { terms:, contents:, id:, delimiter:, attached: Array(data[:attached]) }
        end

        def definition_list(attributes)
          tree = DefinitionListTree.build_dlist_tree(attributes.fetch(:items))
          tree.attrs = attributes[:attrs] if attributes[:attrs]
          tree
        end

        # Inline formatting (bold, italic, highlight, monospace): the
        # constrained/unconstrained flag arrives as a binding default.
        def formatting(attributes)
          { content: Transformer.extract_inline_content(attributes.fetch(:subtree)),
            unconstrained: attributes.fetch(:unconstrained) }
        end

        def span(attributes)
          raw = attributes.fetch(:span)
          { text: raw[:text], unconstrained: attributes.fetch(:unconstrained), attributes: raw[:attribute_list] }
        end

        def script(attributes)
          { content: Transformer.extract_simple_inline_content(attributes.fetch(:script)) }
        end

        def link(attributes)
          raw = attributes.fetch(:link)
          { path: raw[:path].to_s, name: raw[:text]&.to_s }
        end

        def cross_reference(attributes)
          raw = attributes.fetch(:xref)
          { href: raw[:href].to_s, args: raw[:text] ? [raw[:text].to_s] : [] }
        end

        def inline_image(attributes)
          raw = attributes.fetch(:inline_image)
          promoted, residual = Model::Image::AttributeExtractor.call(
            Transformer::AttributeListNormalizer.coerce(raw[:attribute_list]), Model::Image::InlineImage
          )
          { src: raw[:path], attributes: residual, **promoted }
        end

        # Both passthrough forms carry an opaque payload; `form` records the
        # syntax so the serializer can round-trip it.
        def passthrough(attributes)
          { content: attributes.fetch(:passthrough)[:raw].to_s, form: 'triple' }
        end

        # Typographic quotes collapse to the single Unicode character at
        # parse time (shared TypographicQuotes table).
        def typographic_quote(attributes)
          { content: Ceradoc::AsciiDoc::TypographicQuotes.char_for(attributes.fetch(:pattern)) }
        end

        # Footnote text arrives as a string or (empty reference) a sequence.
        def footnote(attributes)
          raw = attributes.fetch(:footnote)
          text = raw.is_a?(Array) ? raw.map(&:to_s).join : raw.to_s
          attributes.key?(:id) ? { text:, id: attributes[:id].to_s } : { text: }
        end

        def stem(attributes)
          raw = attributes.fetch(:stem)
          { type: raw[:stem_type], content: raw[:content] }
        end
      end

      # The table's registries: model names to classes (lazily resolved,
      # so bound rules never load the model set up front) and hook names
      # to callables. The artifact table references both by name only.
      MODELS = ->(name) { Model.const_get(name) }

      HOOKS = {
        'header' => Hooks.method(:header),
        'paragraph' => Hooks.method(:paragraph),
        'list_item' => Hooks.method(:list_item),
        'list' => Hooks.method(:list),
        'dlist_term' => Hooks.method(:dlist_term),
        'definition_list_item' => Hooks.method(:definition_list_item),
        'definition_list' => Hooks.method(:definition_list),
        'formatting' => Hooks.method(:formatting),
        'span' => Hooks.method(:span),
        'script' => Hooks.method(:script),
        'link' => Hooks.method(:link),
        'cross_reference' => Hooks.method(:cross_reference),
        'inline_image' => Hooks.method(:inline_image),
        'passthrough' => Hooks.method(:passthrough),
        'typographic_quote' => Hooks.method(:typographic_quote),
        'footnote' => Hooks.method(:footnote),
        'stem' => Hooks.method(:stem),
        'text' => StructureHooks.method(:text),
        'text_with_break' => StructureHooks.method(:text_with_break),
        'unparsed' => StructureHooks.method(:unparsed),
        'block' => StructureHooks.method(:block),
        'admonition' => StructureHooks.method(:admonition),
        'block_image' => StructureHooks.method(:block_image),
        'table_cell' => StructureHooks.method(:table_cell),
        'unwrap_cell' => StructureHooks.unwrap(:cell),
        'unwrap_row' => StructureHooks.unwrap(:row),
        'table' => StructureHooks.method(:table),
        'title' => StructureHooks.method(:title),
        'section' => StructureHooks.method(:section),
        'document' => StructureHooks.method(:document),
        'comment_line' => StructureHooks.method(:comment_line),
        'comment_block' => StructureHooks.method(:comment_block),
        'tag' => StructureHooks.method(:tag),
        'named_attribute' => StructureHooks.method(:named_attribute),
        'attribute_list' => StructureHooks.method(:attribute_list),
        'attribute' => StructureHooks.method(:attribute),
        'include' => StructureHooks.method(:include)
      }.freeze

      class << self
        # @return [Ceradoc::BindingInflater] the inflater for the bound
        #   rules, built from the table embedded in the artifact
        def inflater
          @inflater ||= Ceradoc::BindingInflater.from_table(
            Parser::GrammarBackend.model_bindings, models: MODELS, hooks: HOOKS
          )
        end
      end
    end
  end
end
