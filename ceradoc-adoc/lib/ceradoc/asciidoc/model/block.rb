# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Block
        # Autoload block types lazily
        autoload :Core, 'ceradoc/asciidoc/model/block/core'
        autoload :Example, 'ceradoc/asciidoc/model/block/example'
        autoload :Literal, 'ceradoc/asciidoc/model/block/literal'
        autoload :Listing, 'ceradoc/asciidoc/model/block/listing'
        autoload :Open, 'ceradoc/asciidoc/model/block/open'
        autoload :Pass, 'ceradoc/asciidoc/model/block/pass'
        autoload :Quote, 'ceradoc/asciidoc/model/block/quote'
        autoload :Side, 'ceradoc/asciidoc/model/block/side'
        autoload :SourceCode, 'ceradoc/asciidoc/model/block/source_code'
        autoload :ReviewerComment, 'ceradoc/asciidoc/model/block/reviewer_comment'
      end
    end
  end
end
