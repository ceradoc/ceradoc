# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class Core < Base
            def to_adoc(model, _options = {})
              @model = model
              _anchor = @model.anchor.nil? ? '' : serialize_child(@model.anchor).to_s
              _attrs = @model.attrs.to_adoc(show_empty: false).to_s
              content = +"\n"

              @model.items.each do |item|
                c = serialize_child(item)
                next if c.empty?

                # If there's a list inside a list directly, we want to
                # skip adding an empty list item.
                # See: https://github.com/ceradoc/ceradoc/issues/96
                unless item.is_a?(Ceradoc::AsciiDoc::Model::List::Core)
                  # Use item's own marker if available, otherwise fall back to list prefix
                  item_marker = item.marker || prefix
                  content << item_marker.to_s
                  content << ' ' if c[0] != ' '
                end
                content << c
              end

              # A list is terminated by a blank line (#376): without it,
              # the next block's first line re-parses as a continuation
              # line of the last item. Item-embedded nested lists strip
              # this back to a single newline (see List::Item).
              "#{_anchor}#{_attrs}#{content}\n"
            end

            private

            def prefix
              @model.prefix
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Ceradoc::AsciiDoc::Model::List::Core, List::Core)
      end
    end
  end
end
