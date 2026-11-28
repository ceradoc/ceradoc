# frozen_string_literal: true

require_relative '../element_serializer'

module Coridoc
  module Markdown
    class Serializer
      module Serializers
        class Blockquote < ElementSerializer
          handles_type ::Coridoc::Markdown::Blockquote

          # Mirrors the parser's paragraph_interrupt rule: a line matching
          # any of these cannot continue a paragraph lazily.
          LAZY_INTERRUPTING = /\A(?:
              \s*\z |
                [ ]{0,3}(?:\#|>|(?:`|~){3,}|\{) |
                [ ]{0,3}[-*+][ \t] |
                [ ]{0,3}\d+[.)][ \t] |
                [ ]{0,3}[-*_][ \t]*(?:[-*_][ \t]*){2,} |
                :[ \t]
            )/x

          def call(element, _ctx)
            element.content.to_s.lines.each_with_index.map do |line, index|
              if index.zero? || !lazy_continuable?(line)
                "> #{line}"
              else
                # Lazy continuation, mirroring the parser's block_quote_cont:
                # a bare line rejoins the quote only when it cannot interrupt
                # a paragraph. An explicit `> ` on such a line can change the
                # parse (e.g. `> -` closes the paragraph as a setext underline
                # where a lazy `-` continues it), so the quote's shape would
                # differ on re-parse.
                line
              end
            end.join
          end

          private

          def lazy_continuable?(line)
            !line.match?(LAZY_INTERRUPTING)
          end
        end
      end
    end
  end
end
