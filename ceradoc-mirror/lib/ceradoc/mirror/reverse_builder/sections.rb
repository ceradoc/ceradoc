# frozen_string_literal: true

module Ceradoc
  module Mirror
    module ReverseBuilder
      # `sections` is a structural container only — unwrap directly into
      # an array. MirrorToCoreModel#build_content flattens arrays.
      class Sections < Base
        def build(node)
          build_content(node)
        end
      end
    end
  end
end
