# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Parser
      # AsciiDoc frontmatter extractor.
      #
      # Delegates to the shared +Coridoc::CoreModel::FrontmatterBlock::TextSplitter+
      # — the single source of truth for the `---\n...\n---\n` convention
      # (DRY). AsciiDoc retains a local parser module for discoverability
      # and as the seam for any format-specific extensions should they arise
      # (e.g., recognizing AsciiDoc-style front matter variants).
      module FrontmatterParser
        class << self
          def call(text)
            Coridoc::CoreModel::FrontmatterBlock::TextSplitter.call(text)
          end
        end

        Result = Coridoc::CoreModel::FrontmatterBlock::TextSplitter::Result
      end
    end
  end
end
