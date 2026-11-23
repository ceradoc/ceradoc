# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Blockquote < Base
        INSTANCE = new

        def to_coridoc(node, state = {})
          id = node['id']
          cite = node['cite']
          content = treat_children_coridoc(node, state)

          Coridoc::CoreModel::QuoteBlock.new(
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
