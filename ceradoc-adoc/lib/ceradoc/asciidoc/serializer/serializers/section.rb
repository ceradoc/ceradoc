# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Section < Base
          def to_adoc(model, options_or_context = {})
            context = normalize_context(options_or_context)
            parts = []

            parts << "\n"
            parts << "#{serialize_child(model.anchor, context)}\n" if model.anchor
            parts << "#{model.attrs.map { |a| serialize_child(a, context) }.join(',')}\n" unless model.attrs.empty?
            parts << serialize_child(model.title, context) if model.title

            # Process contents — a block stream: blank-line runs at the
            # chunk boundaries are capped at one blank line so spacing
            # does not accumulate into the previous element's
            # line_break on re-parse (#376).
            content_str = serialize_block_stream(model.contents, context)

            # A block of " +\n"s isn't parsed correctly. It needs to start
            # with something.
            content_str = "&nbsp;#{content_str}" if content_str.start_with?(" +\n")

            parts << content_str
            parts << serialize_block_stream(model.sections, context)
            parts << "\n"

            parts.join
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Ceradoc::AsciiDoc::Model::Section, Serializers::Section)
    end
  end
end
