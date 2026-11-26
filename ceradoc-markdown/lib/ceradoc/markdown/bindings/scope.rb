# frozen_string_literal: true

module Ceradoc
  module Markdown
    module Bindings
      # Document-scoped state for the stateful rules: the Attribute List
      # Definition table. One Scope per parsed document, handed to the
      # scoped hooks by the BindingInflater.
      class Scope
        def initialize
          @definitions = {}
        end

        # Register an ALD under its name.
        def define(name, attrs)
          @definitions[name] = Bindings.model('AttributeList').new(name: name, **attribute_list_attrs(attrs))
        end

        # An IAL naming a registered ALD resolves to it; anything else is
        # a fresh attribute list.
        def resolve(ial_content)
          content = ial_content.strip
          return @definitions[content] if content.match?(/\A\w+\z/) && @definitions.key?(content)

          attrs = Captures.parse_ial_content(content)
          Bindings.model('AttributeList').new(**attribute_list_attrs(attrs))
        end

        private

        # parse_to_hash yields attributes as a plain hash; the model
        # layer carries them as NamedValue pairs.
        def attribute_list_attrs(parsed)
          {
            id: parsed[:id],
            classes: parsed[:classes],
            attributes: parsed[:attributes].to_a.map do |key, value|
              Bindings.model('NamedValue').new(name: key.to_s, value: value.to_s)
            end
          }
        end
      end
    end
  end
end
