# frozen_string_literal: true

module Coridoc
  module Markdown
    module Parser
      autoload :BlockParser, "#{__dir__}/block_parser"
      autoload :InlineParser, "#{__dir__}/inline_parser"
      autoload :AstProcessor, "#{__dir__}/ast_processor"
    end
  end
end
