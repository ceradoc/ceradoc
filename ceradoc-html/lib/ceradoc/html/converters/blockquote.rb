# frozen_string_literal: true

module Ceradoc
  module Html
    module Converters
      class Blockquote < Base
        INSTANCE = new

        def to_ceradoc(node, state = {})
          id = node['id']
          cite = node['cite']
          content = treat_children_ceradoc(node, state)

          Ceradoc::CoreModel::QuoteBlock.new(
            children: content,
            id: id,
            attribution: cite
          )
        end
      end

      register :blockquote, Blockquote::INSTANCE
    end
  end
end
