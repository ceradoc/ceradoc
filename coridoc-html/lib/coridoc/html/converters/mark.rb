# frozen_string_literal: true

module Coridoc
  module Html
    module Converters
      class Mark < Markup
        INSTANCE = new

        def coridoc_format_type
          'highlight'
        end

        def markup_ancestor_tag_names
          %w[mark]
        end
      end

      register :mark, Mark::INSTANCE
    end
  end
end
