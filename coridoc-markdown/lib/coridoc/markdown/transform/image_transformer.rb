# frozen_string_literal: true

module Coridoc
  module Markdown
    module Transform
      module ImageTransformer
        class << self
          def transform_image(image)
            Coridoc::Markdown::Image.new(
              src: image.src,
              alt: image.alt.to_s,
              title: image.title
            )
          end
        end

        FromCoreModel.register(CoreModel::Image, method(:transform_image))
      end
    end
  end
end
