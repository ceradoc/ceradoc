# frozen_string_literal: true

module Ceradoc
  module Roundtrip
    class Vector
      # Adversarial vector corpus: small constructs that stress inline
      # and block machinery harder than the fixture files do. Every
      # entry passes the round-trip harness (they pin parity, not known
      # bugs) and was verified against Checker before being added.
      module Adversarial
        ASCIIDOC = {
          # inline: escaped markup must stay literal
          'inline-escapes' => "Not bold: \\*text\\* and \\_underline\\_ stay literal.\n",
          # block: header-ordered attributes + block title + delimited content
          'block-title-attrs' => ".Block title\n[source,ruby]\n----\nputs 1\n----\n",
          # block: definition list with an attached admonition block
          'dlist-attached-admonition' => "term:: def\n+[NOTE]\n====\nnote\n====\n",
          # block: table with a colspan marker mid-row
          'table-colspan' => "|===\n|a 2+|b\n|c |d\n|===\n",
          # inline: unicode punctuation inside constrained markup
          'unicode-punct' => "*Émphasis* with ☃ and 「quotes」 — em—dash\n",
          # block: delimited block nested inside a delimited block
          'nested-content-blocks' => "====\n[source]\n----\ncode\n----\n====\n"
        }.freeze

        MARKDOWN = {
          # inline: escaped emphasis markers must stay literal
          'inline-escapes' => "Not emphasis: \\*stars\\* and \\_under\\_ stay literal.\n",
          # block: loose list (blank lines between items) with nesting
          'list-loose-nesting' => "- a\n\n  - b\n\n- c\n",
          # inline: links and images with titles plus an autolink
          'link-image-titles' => "[a](b \"c\") ![d](e \"f\") <https://auto.link>\n",
          # block: alignment-row table
          'table-alignment' => "| l | c | r |\n|---|:-:|--:|\n| a | b | c |\n",
          # inline: backslash hard break between lines
          'hard-break-backslash' => "one\\\ntwo\n",
          # block: blockquote containing a nested list
          'blockquote-nested' => "> quoted *bold*\n>\n> - list in quote\n"
        }.freeze

        module_function

        # @return [Array<Case>]
        def all
          { asciidoc: ASCIIDOC, markdown: MARKDOWN }.flat_map do |format, table|
            table.map do |name, text|
              Case.new("#{format}:adversarial/#{name}", format, text, 'adversarial vector corpus')
            end
          end
        end
      end
    end
  end
end
