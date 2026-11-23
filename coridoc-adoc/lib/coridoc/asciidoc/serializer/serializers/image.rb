# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload image serializers
        module Image
          autoload :Core, 'coridoc/asciidoc/serializer/serializers/image/core'
        end
      end
    end
  end
end
