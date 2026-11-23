# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload block serializers
        module Block
          autoload :Core, 'coridoc/asciidoc/serializer/serializers/block/core'
          autoload :Example, 'coridoc/asciidoc/serializer/serializers/block/example'
          autoload :Listing, 'coridoc/asciidoc/serializer/serializers/block/listing'
          autoload :Literal, 'coridoc/asciidoc/serializer/serializers/block/literal'
          autoload :Open, 'coridoc/asciidoc/serializer/serializers/block/open'
          autoload :Pass, 'coridoc/asciidoc/serializer/serializers/block/pass'
          autoload :Quote, 'coridoc/asciidoc/serializer/serializers/block/quote'
          autoload :ReviewerComment, 'coridoc/asciidoc/serializer/serializers/block/reviewer_comment'
          autoload :Side, 'coridoc/asciidoc/serializer/serializers/block/side'
          autoload :SourceCode, 'coridoc/asciidoc/serializer/serializers/block/source_code'
        end
      end
    end
  end
end
