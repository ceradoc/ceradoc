# frozen_string_literal: true

$LOAD_PATH.unshift('../coridoc/lib')
require 'coridoc'
require 'pp'

def pretty_print_obj(obj)
  sio = StringIO.new
  PP.pp(obj, sio, 69)
  puts sio.string
end

def print_parsed(str)
  parse = Coridoc::Parser::Base.new.parse(str)
  puts str
  puts ''
  pretty_print_obj parse[:document]
  puts ''
  doc = Coridoc::Transformer.transform(parse[:document])
  pp doc
  puts Coridoc::Generator.gen_adoc(doc)
end

content = <<~END
  [a='quoted named']
  ****
  block
  ****
END

print_parsed(content)
