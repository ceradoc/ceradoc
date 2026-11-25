# frozen_string_literal: true

module Ceradoc
  module Html
    module Errors
      class Error < Ceradoc::Error; end
      class UnknownTagError < Error; end
      class InvalidConfigurationError < Error; end
    end
  end
end
