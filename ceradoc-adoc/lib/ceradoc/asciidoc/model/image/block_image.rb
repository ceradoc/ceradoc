# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Image
        class BlockImage < Ceradoc::AsciiDoc::Model::Image::Core
          def block_level?
            true
          end

          # Autoload nested AttributeList class
          autoload :AttributeList, 'ceradoc/asciidoc/model/image/block_image/attribute_list'

          attribute :colons, :string, default: -> { '::' }
          attribute :attributes,
                    Ceradoc::AsciiDoc::Model::Image::BlockImage::AttributeList,
                    default: lambda {
                      ::Ceradoc::AsciiDoc::Model::AttributeList.new
                    }

          # Block images support the legacy positional form
          # `image::target[alt, caption, role, ...]`, so the 2nd positional
          # is promoted to `caption` (Asciidoctor image block macro shorthand).
          # @return [Array<Symbol>]
          def self.promoted_positional
            %i[alt caption]
          end
        end
      end
    end
  end
end
