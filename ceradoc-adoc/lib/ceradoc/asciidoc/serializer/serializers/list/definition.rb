# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Definition < Base
            def to_adoc(model, _options = {})
              @model = model
              _attrs = @model.attrs.to_adoc(show_empty: false).to_s
              prefix = _attrs.empty? ? '' : "#{_attrs}\n"
              content = "\n#{prefix}"
              @model.items.each do |item|
                # Pass delimiter to item serialization
                serialized = serialize_child_with_options(item, delimiter: @model.delimiter)
                content << serialized
              end
              # List terminator blank (#376) — same contract as List::Core.
              "#{content}\n"
            end

            private

            def serialize_child_with_options(child, options = {})
              serializer_class = ElementRegistry.lookup(child.class)
              serializer = serializer_class.new
              serializer.to_adoc(child, options)
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::List::Definition, List::Definition)
      end
    end
  end
end
