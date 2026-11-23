# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Image
        # Autoload image types lazily
        autoload :Core, 'coridoc/asciidoc/model/image/core'
        autoload :InlineImage, 'coridoc/asciidoc/model/image/inline_image'
        autoload :BlockImage, 'coridoc/asciidoc/model/image/block_image'
        autoload :AttributeExtractor, 'coridoc/asciidoc/model/image/attribute_extractor'
      end
    end
  end
end
