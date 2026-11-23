# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Block
        # Autoload block types lazily
        autoload :Core, 'coridoc/asciidoc/model/block/core'
        autoload :Example, 'coridoc/asciidoc/model/block/example'
        autoload :Literal, 'coridoc/asciidoc/model/block/literal'
        autoload :Listing, 'coridoc/asciidoc/model/block/listing'
        autoload :Open, 'coridoc/asciidoc/model/block/open'
        autoload :Pass, 'coridoc/asciidoc/model/block/pass'
        autoload :Quote, 'coridoc/asciidoc/model/block/quote'
        autoload :Side, 'coridoc/asciidoc/model/block/side'
        autoload :SourceCode, 'coridoc/asciidoc/model/block/source_code'
        autoload :ReviewerComment, 'coridoc/asciidoc/model/block/reviewer_comment'
      end
    end
  end
end
