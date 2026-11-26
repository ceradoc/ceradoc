# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # Verbatim/delimited block reconstruction for the AsciiDoc view:
      # maps a CoreModel block's semantic type to the adoc block model,
      # choosing between the byte-exact prose lines and the
      # structure-faithful container rebuild (#376, see
      # ReviewerBuilding#container_lines).
      module VerbatimBuilding
        def build_verbatim_block(semantic, block, content_text)
          case semantic
          when :source_code
            Ceradoc::AsciiDoc::Model::Block::SourceCode.new(
              id: block.id,
              title: block.title,
              lang: block.language,
              lines: content_text.split("\n"),
              attributes: build_attributes(block)
            )
          when :abstract, :partintro
            # Cast open blocks ([abstract]/[partintro] + `--`): the
            # attribute line must re-emit or the re-parse degrades the
            # block to a plain open block / paragraph (#376).
            Ceradoc::AsciiDoc::Model::Block::Open.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text),
              attributes: cast_attributes(semantic)
            )
          when :quote
            Ceradoc::AsciiDoc::Model::Block::Quote.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text)
            )
          when :example
            Ceradoc::AsciiDoc::Model::Block::Example.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text)
            )
          when :sidebar
            Ceradoc::AsciiDoc::Model::Block::Side.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text)
            )
          when :literal
            Ceradoc::AsciiDoc::Model::Block::Literal.new(
              id: block.id,
              title: block.title,
              lines: content_text.split("\n")
            )
          when :open
            Ceradoc::AsciiDoc::Model::Block::Open.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text)
            )
          when :pass
            Ceradoc::AsciiDoc::Model::Block::Pass.new(
              id: block.id,
              title: block.title,
              lines: content_text.split("\n")
            )
          when :listing
            Ceradoc::AsciiDoc::Model::Block::Listing.new(
              id: block.id,
              title: block.title,
              lines: content_text.split("\n")
            )
          when :verse
            Ceradoc::AsciiDoc::Model::Block::Quote.new(
              id: block.id,
              title: block.title,
              lines: container_lines(block, content_text),
              delimiter: '[verse]'
            )
          when :reviewer
            # Re-emit the [reviewer=NAME] line: without it the
            # re-parse classifies the bare `****` as a plain sidebar
            # and the block class flips (#376). The body is a
            # CONTAINER (typed children — lists, paragraphs), so the
            # lines rebuild from serialized children rather than a
            # flat-text join.
            Ceradoc::AsciiDoc::Model::Block::ReviewerComment.new(
              id: block.id,
              title: block.title,
              lines: container_block_lines(block),
              attributes: reviewer_attributes(block)
            )
          else
            delim = block.delimiter_type.to_s
            delim_char = delim[0]
            delim_len = delim.length

            Ceradoc::AsciiDoc::Model::Block::Core.new(
              id: block.id,
              title: block.title,
              delimiter: delim,
              delimiter_char: delim_char,
              delimiter_len: delim_len,
              lines: content_text.split("\n")
            )
          end
        end

        def verbatim_with_callouts?(semantic, block)
          return false unless %i[source_code listing].include?(semantic)
          return false if block.callouts.nil? || block.callouts.empty?

          true
        end
      end
    end
  end
end
