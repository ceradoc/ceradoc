# frozen_string_literal: true

module Coridoc
  module Markdown
    class CrossReference < Base
      attribute :text, :string
      attribute :target, :string
    end
  end
end
