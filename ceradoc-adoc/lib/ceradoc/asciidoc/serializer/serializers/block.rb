# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload block serializers
        module Block
          autoload :Core, 'ceradoc/asciidoc/serializer/serializers/block/core'
          autoload :Example, 'ceradoc/asciidoc/serializer/serializers/block/example'
          autoload :Listing, 'ceradoc/asciidoc/serializer/serializers/block/listing'
          autoload :Literal, 'ceradoc/asciidoc/serializer/serializers/block/literal'
          autoload :Open, 'ceradoc/asciidoc/serializer/serializers/block/open'
          autoload :Pass, 'ceradoc/asciidoc/serializer/serializers/block/pass'
          autoload :Quote, 'ceradoc/asciidoc/serializer/serializers/block/quote'
          autoload :ReviewerComment, 'ceradoc/asciidoc/serializer/serializers/block/reviewer_comment'
          autoload :Side, 'ceradoc/asciidoc/serializer/serializers/block/side'
          autoload :SourceCode, 'ceradoc/asciidoc/serializer/serializers/block/source_code'
        end
      end
    end
  end
end
