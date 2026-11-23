# frozen_string_literal: true

module Coridoc
  module Html
    module Errors
      class Error < Coridoc::Error; end
      class UnknownTagError < Error; end
      class InvalidConfigurationError < Error; end
    end
  end
end
