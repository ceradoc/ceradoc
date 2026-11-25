# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Image
        # Autoload image types lazily
        autoload :Core, 'ceradoc/asciidoc/model/image/core'
        autoload :InlineImage, 'ceradoc/asciidoc/model/image/inline_image'
        autoload :BlockImage, 'ceradoc/asciidoc/model/image/block_image'
        autoload :AttributeExtractor, 'ceradoc/asciidoc/model/image/attribute_extractor'
      end
    end
  end
end
