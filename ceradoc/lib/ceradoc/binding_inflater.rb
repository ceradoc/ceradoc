# frozen_string_literal: true

require 'yaml'

module Ceradoc
  # Generic raw-tree to typed-model engine behind PARG bindings.
  #
  # A parser yields a raw tree of hashes (capture name => value). A
  # Binding says: a node with exactly these keys is an instance of this
  # model, its attributes assigned from these captures. The inflater
  # instantiates the bound model, recursing through captured
  # collections; everything unbound falls through to a residual (the
  # format's hand-written processing), so a format migrates one rule at
  # a time and nothing changes until a binding exists.
  #
  #   inflater = BindingInflater.new(bindings: [binding])
  #   inflater.inflate(node) { |unbound| legacy_transform(unbound) }
  class BindingInflater
    # One bound rule.
    #
    # @!attribute keys [Array<Symbol>] the exact capture-key set of a node
    # @!attribute model [Class, #call] the model class, or a callable that
    #   returns it (resolved on first use, for lazily loaded classes)
    # @!attribute captures [Hash{Symbol=>Symbol}] attribute => capture key
    # @!attribute defaults [Hash{Symbol=>Object}] attributes fixed by the rule
    # @!attribute via [#call, nil] optional named hook for a rule's semantic
    #   step: receives the assigned attributes, returns the attributes the
    #   model is built from. Pure capture-to-attribute rules need none.
    #   With `model: nil` the hook's return value IS the result (for rules
    #   that build a tree, pass a value through, or return plain data).
    # @!attribute raw [Hash{Symbol=>Symbol}] attribute => capture key, assigned
    #   as captured: never inflated and never sent to the residual. For hooks
    #   that read the raw subtree themselves.
    # @!attribute scoped [Boolean, nil] when true the hook also receives the
    #   context passed to {#inflate} (document-scoped state such as a table
    #   of definitions), as its second argument.
    Binding = Struct.new(:keys, :model, :captures, :defaults, :via, :raw, :scoped, keyword_init: true) do
      def matches?(node)
        node.is_a?(Hash) && node.keys.sort == keys.sort
      end

      def model_class
        model.is_a?(Class) || model.nil? ? model : model.call
      end
    end

    # Build an inflater from the model-bindings table a PARG artifact
    # embeds (`parsanol parg bindings` dumps the same table).
    #
    # @param table [Hash, nil] the table (see SCHEMA below); nil = no bindings
    # @param models [#call] resolves a model name to its class, lazily
    # @param hooks [Hash{String=>#call}, #call, nil] the hook registry the
    #   gem provides: name => callable, or a callable resolving a name to
    #   one. Required when any rule names a `via` hook.
    # @param groups [Array<String>, nil] rule-group filter: a rule tagged
    #   `group:` is included only when its tag is listed; untagged rules
    #   (shared between inflaters, or the whole of a single-inflater
    #   grammar) are always included. nil = every rule.
    #
    # The table schema (ceradoc#385, stage 1 of the SSOT tables):
    #
    #   version: '1.1'
    #   hooks:                     # the hook surface the table references,
    #     header: Hooks#header     # name => verb-ref (documentation; the
    #   rules:                     # callables come from `hooks:` above)
    #     header:
    #       keys: [header]         # the node's exact capture-key set
    #       model: Header          # registry name; null = hook-only rule
    #       captures: {t: title}   # attribute => capture, inflated recursively
    #       children: {h: header}  # same feed, for captures holding nested nodes
    #       defaults: {lang: en}   # attributes fixed by the rule (JSON values)
    #       raw: {ial: ial}        # attribute => capture, assigned as captured
    #       via: header            # hook name, declared in the hooks map
    #       optional: [title]      # captures that may be absent; expands to
    #                              # one binding per present/absent combination
    #       scoped: false          # hook also receives the inflate context
    #       group: block           # optional tag; see the `groups:` argument
    #
    # Version 1 tables (parsanol's native shape) are the v1.1 subset
    # without hooks/via/raw/optional/scoped/group; they keep their
    # meaning unchanged.
    def self.from_table(table, models:, hooks: nil, groups: nil)
      return new(bindings: []) unless table

      version = table['version']
      raise ArgumentError, "unsupported model_bindings version #{version.inspect}" unless version == 1 || version.to_s == '1.1'

      registry = HookRegistry.new(table.fetch('hooks', {}), hooks)
      bindings = table.fetch('rules').flat_map do |name, rule|
        rule_bindings(name, rule, models, registry, groups)
      end
      new(bindings: bindings)
    end

    # Load and validate a model-bindings sidecar (YAML or JSON) for the
    # compile pipeline to embed. parsanol's own sidecar loader pins the
    # v1 shape, so the gems embed their v1.1 tables through this (the
    # checksum sealing itself stays parsanol's ModelBindings.embed).
    def self.load_table(path)
      text = File.read(path, encoding: Encoding::UTF_8)
      raw = path.match?(/\.ya?ml\z/i) ? YAML.safe_load(text) : JSON.parse(text)
      validate_table(raw)
    end

    TABLE_FIELDS = %w[keys model captures children defaults raw via optional scoped group].freeze

    # Validate a table against the schema documented on {from_table} and
    # return it normalized to string keys.
    def self.validate_table(raw)
      raise ArgumentError, 'model bindings: expected a mapping' unless raw.is_a?(Hash)

      version = raw['version']
      raise ArgumentError, "model bindings: unsupported version #{version.inspect} (want 1 or '1.1')" unless version == 1 || version.to_s == '1.1'

      rules = raw['rules']
      raise ArgumentError, 'model bindings: `rules` must be a mapping' unless rules.is_a?(Hash)

      hooks = raw.fetch('hooks', {})
      raise ArgumentError, 'model bindings: `hooks` must be a mapping' unless hooks.is_a?(Hash)

      { 'version' => version, 'hooks' => hooks,
        'rules' => rules.to_h { |name, rule| [name.to_s, validate_rule(name, rule, hooks)] } }
    end

    def self.validate_rule(name, rule, hooks)
      raise ArgumentError, "model bindings: rule #{name.inspect} must be a mapping" unless rule.is_a?(Hash)

      unknown = rule.keys - TABLE_FIELDS
      raise ArgumentError, "model bindings: rule #{name.inspect} has unknown field #{unknown.first.inspect}" unless unknown.empty?
      raise ArgumentError, "model bindings: rule #{name.inspect} needs non-empty `keys`" unless rule['keys'].is_a?(Array) && rule['keys'].any?

      model = rule['model']
      raise ArgumentError, "model bindings: rule #{name.inspect} needs a `model` name or null" unless model.nil? || (model.is_a?(String) && !model.empty?)

      via = rule['via']
      raise ArgumentError, "model bindings: rule #{name.inspect} names undeclared hook #{via.inspect}" if via && !hooks.key?(via.to_s)
      raise ArgumentError, "model bindings: rule #{name.inspect} `optional` must name captures" unless Array(rule['optional']).all?(String)

      normalized = rule.transform_keys(&:to_s)
      normalized['keys'] = normalized.fetch('keys').map(&:to_s)
      normalized
    end

    # The bindings one table rule expands to: one per present/absent
    # combination of its `optional` captures, none when it lists none.
    def self.rule_bindings(name, rule, models, registry, groups)
      return [] if groups && rule['group'] && !groups.include?(rule['group'])

      model_name = rule['model']
      model = model_name.nil? || model_name.empty? ? nil : -> { models.call(model_name) }
      # Both attribute => capture maps feed the same recursive inflation;
      # raw captures are assigned as captured. An expansion keeps only
      # the captures the key set actually names.
      feed = rule.fetch('captures', {}).merge(rule.fetch('children', {}))
                 .to_h { |attribute, key| [attribute.to_sym, key.to_sym] }
      raw = rule.fetch('raw', {}).to_h { |attribute, key| [attribute.to_sym, key.to_sym] }
      defaults = rule.fetch('defaults', {}).transform_keys(&:to_sym)
      via = rule['via'] && registry.resolve(rule['via'], name)

      key_sets(rule.fetch('keys').map(&:to_sym), Array(rule['optional']).map(&:to_sym)).map do |keys|
        Binding.new(
          keys: keys, model: model,
          captures: feed.select { |_attribute, key| keys.include?(key) },
          raw: raw.select { |_attribute, key| keys.include?(key) },
          defaults: defaults, via: via, scoped: rule['scoped'] || nil
        )
      end
    end

    def self.key_sets(keys, optional)
      required = keys - optional
      (0..optional.size).flat_map { |n| optional.combination(n).map { |picked| required + picked } }
    end
    private_class_method :validate_rule, :rule_bindings, :key_sets

    # Resolves a rule's `via` hook name to its callable. The table's
    # top-level `hooks` map declares which names the table references;
    # the gem's registry (name => callable, or a callable resolving
    # names) supplies the callables. Both halves must agree.
    class HookRegistry
      def initialize(declared, registry)
        @declared = declared
        @registry = registry
      end

      def resolve(name, rule)
        raise ArgumentError, "model bindings: rule #{rule.inspect} names undeclared hook #{name.inspect}" unless @declared.key?(name)

        callable = @registry.is_a?(Hash) ? @registry[name] : @registry&.call(name)
        raise ArgumentError, "model bindings: rule #{rule.inspect}: hook #{name.inspect} is not provided" unless callable.respond_to?(:call)

        callable
      end
    end

    def initialize(bindings:)
      @bindings = bindings
    end

    # @return [Array<Binding>] the bindings, for callers that need to know
    #   which rules are bound (e.g. a corpus guard)
    attr_reader :bindings

    def bound?(node)
      !binding_for(node).nil?
    end

    # @param node [Object] a raw tree node
    # @param context [Object, nil] document-scoped state, handed to the hooks
    #   of scoped bindings and carried through nested nodes
    # @yield [Object] an unbound node, handed to the residual
    # @return [Object] the model for a bound node, else the residual's result
    def inflate(node, context = nil, &residual)
      binding = binding_for(node)
      return yield(node) unless binding

      attributes = binding.defaults.dup
      binding.captures.each { |attribute, key| attributes[attribute] = inflate_value(node[key], context, &residual) }
      binding.raw&.each { |attribute, key| attributes[attribute] = node[key] }
      attributes = call_hook(binding, attributes, context) if binding.via
      binding.model ? binding.model_class.new(**attributes) : attributes
    end

    private

    def binding_for(node)
      @bindings.find { |binding| binding.matches?(node) }
    end

    def call_hook(binding, attributes, context)
      binding.scoped ? binding.via.call(attributes, context) : binding.via.call(attributes)
    end

    def inflate_value(value, context, &residual)
      case value
      when Array then value.map { |item| inflate_value(item, context, &residual) }
      when Hash then inflate(value, context, &residual)
      else value.respond_to?(:to_str) ? value.to_str : value
      end
    end
  end
end
