# frozen_string_literal: true

module Ceradoc
  module Markdown
    # Polymorphic data-serialization registry for the Markdown model
    # layer (#389): the mirror of CoreModel::Serialization. Heterogeneous
    # collections (typed `Base`) need a class discriminator to reload
    # from JSON/YAML; the walker generates the key_value mappings for
    # every Base subclass and dispatches marked collections through
    # Markdown::Serialization::POLYMORPHIC. Collections opt in at their
    # declaration with `polymorphic_class: true`.
    #
    # Framework-generated through the lutaml-model DSL only (repo law:
    # no hand-rolled to_h/to_json anywhere). Adding a model = defining
    # it — the walker picks it up.
    module Serialization
      TYPE_TO_CLASS = {}
      POLYMORPHIC = { attribute: 'type', class_map: TYPE_TO_CLASS }.freeze
      TYPE_WIRE_KEY = 'type'

      class << self
        def demodulized_name(klass)
          klass.name.to_s.split('::').last
        end

        def snake_case(class_name)
          class_name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        end

        private

        def walk_model_tree(namespace, visited)
          namespace.constants.each do |name|
            k = namespace.const_get(name)
            next if visited.include?(k)

            visited << k
            if k.is_a?(Class) && k < Base
              register_model(k)
              walk_model_tree(k, visited)
            elsif k.is_a?(Module)
              walk_model_tree(k, visited)
            end
          end
        end

        def register_model(klass)
          full_name = klass.name
          return if full_name.nil?

          TYPE_TO_CLASS[demodulized_name(klass)] = full_name
          attrs = klass.attributes
          type_key = TYPE_WIRE_KEY
          rules = attrs.except(:type).transform_values do |attr|
            options = { render_empty: true }
            options[:polymorphic] = POLYMORPHIC if attr.polymorphic?
            options
          end
          klass.key_value do
            map type_key, to: :type, render_default: true
            rules.each do |name, options|
              map name.to_s, to: name, **options
            end
          end
        end
      end

      walk_model_tree(Markdown, [])
      TYPE_TO_CLASS.freeze
    end
  end
end
