# frozen_string_literal: true

module Ceradoc
  module Markdown
    # Hand-written behavior modules, one per model that needs methods beyond
    # its attributes. Both the hand-written models and the schema-generated
    # classes prepend the same module, so behavior has a single source.
    module Behaviors
      autoload :AttributeList, 'ceradoc/markdown/behaviors/attribute_list'
      autoload :Admonition, 'ceradoc/markdown/behaviors/admonition'
      autoload :Document, 'ceradoc/markdown/behaviors/document'
      autoload :Extension, 'ceradoc/markdown/behaviors/extension'
      autoload :Heading, 'ceradoc/markdown/behaviors/heading'
      autoload :Math, 'ceradoc/markdown/behaviors/math'
      autoload :Text, 'ceradoc/markdown/behaviors/text'
    end
  end
end
