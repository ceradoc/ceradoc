# frozen_string_literal: true

module Coridoc
  module Markdown
    # Code model representing inline code (`code`).
    #
    class Code < Base
      attribute :text, :string
    end
  end
end
