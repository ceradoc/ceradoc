# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      class Document < Base
        def build(node)
          attrs = node.attrs
          CoreModel::DocumentElement.new(
            title: attrs&.title,
            id: attrs&.id,
            attributes: CoreModel::Metadata.new(
              entries: Array(attrs&.entries).map do |entry|
                CoreModel::MetadataEntry.new(key: entry.key, value: entry.value)
              end
            ),
            children: build_content(node)
          )
        end
      end
    end
  end
end
