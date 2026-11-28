# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class Image < Base
        def build(node)
          attrs = node.attrs
          CoreModel::Image.new(
            src: attrs&.src,
            alt: attrs&.alt,
            title: attrs&.title,
            caption: attrs&.caption,
            width: attrs&.width,
            height: attrs&.height,
            role: attrs&.role,
            link: attrs&.link,
            # The inline/block distinction is meaning (it decides macro
            # form on the forward serialization), not presentation — the
            # wire carries it on Attrs, so restore it here.
            inline: attrs&.inline || false
          )
        end
      end
    end
  end
end
