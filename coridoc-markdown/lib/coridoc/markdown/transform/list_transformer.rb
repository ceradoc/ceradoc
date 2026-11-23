# frozen_string_literal: true

module Coridoc
  module Markdown
    module Transform
      module ListTransformer
        class << self
          def transform_list(list)
            items = Array(list.items).map do |item|
              transform_list_item(item)
            end

            Coridoc::Markdown::List.new(
              ordered: list.marker_type == 'ordered',
              items: items
            )
          end

          def transform_list_item(item)
            content = item.renderable_content
            has_structured = content.is_a?(Array) && content.any? do |c|
              !c.is_a?(CoreModel::TextContent)
            end
            if has_structured
              children = content.map { |c| BlockTransformer.transform_content_node(c) }
              Coridoc::Markdown::ListItem.new(text: item.flat_text, children: children)
            else
              Coridoc::Markdown::ListItem.new(text: item.flat_text)
            end
          end

          def transform_definition_list(dl)
            # flat_map because multi-term `<dt>`'s emit multiple
            # DefinitionTerms per CoreModel DefinitionItem.
            items = Array(dl.items).flat_map do |item|
              definitions = Array(item.definitions).map do |defn|
                Coridoc::Markdown::DefinitionItem.new(content: defn.to_s)
              end
              terms = item.terms
              term_strings = terms.nil? || terms.empty? ? [item.term.to_s] : terms.map(&:to_s)
              term_strings.map do |term_text|
                Coridoc::Markdown::DefinitionTerm.new(
                  text: term_text,
                  definitions: definitions
                )
              end
            end

            Coridoc::Markdown::DefinitionList.new(items: items)
          end
        end

        FromCoreModel.register(CoreModel::ListBlock, method(:transform_list))
        FromCoreModel.register(CoreModel::DefinitionList, method(:transform_definition_list))
      end
    end
  end
end
