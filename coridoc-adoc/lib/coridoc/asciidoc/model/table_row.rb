# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      class TableRow < Base
        attribute :columns, Coridoc::AsciiDoc::Model::TableCell, collection: true
        attribute :header, :boolean, default: -> { false }

        def table_header_row?
          header
        end

        def asciidoc?
          columns&.any? { |c| c.is_a?(Coridoc::AsciiDoc::Model::TableCell) && c.asciidoc? } || false
        end

        # NOTE: underline_for provides trailing newline for table row serialization.
        # The method name follows AsciiDoc table formatting conventions.
        def underline_for
          "\n"
        end
      end
    end
  end
end
