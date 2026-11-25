# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload image serializers
        module Image
          autoload :Core, 'ceradoc/asciidoc/serializer/serializers/image/core'
        end
      end
    end
  end
end
