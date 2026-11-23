# frozen_string_literal: true

require 'coridoc'

# This works with the update to Lutaml Model.
def parse(str)
  ast = Coridoc::Parser.parse(str)
  result = Coridoc::Transformer.transform(ast)

  {
    ast:,
    result:
  }
end

def parse_file(file_path = 'coridoc/spec/fixtures/sample.adoc')
  str = File.read(file_path)
  parse(str)
end

def menu
  puts <<~EOM
    🔨 Welcome to Coridoc ⨯ \x1b[31;1m#{$PROGRAM_NAME}\x1b[m!

      parse(str)        - Given an asciidoc string, return AST and doc model
      parse_file(file)  - Given a file path, return AST and doc model

    [[general commands]]

      menu              - prints this menu

  EOM
end

menu
