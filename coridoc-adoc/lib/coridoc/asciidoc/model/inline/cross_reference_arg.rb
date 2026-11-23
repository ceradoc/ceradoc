# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Inline
        class CrossReferenceArg < Base
          attribute :key, :string
          attribute :delimiter, :string
          attribute :value, :string
        end
      end
    end
  end
end
