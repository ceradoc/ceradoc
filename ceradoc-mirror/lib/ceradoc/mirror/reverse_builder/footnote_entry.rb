# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class FootnoteEntry < Base
        def build(node)
          attrs = node.attrs
          CoreModel::Footnote.new(id: attrs&.id, content: extract_text(node))
        end
      end
    end
  end
end
