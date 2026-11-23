# frozen_string_literal: true

module Coridoc
  module Markdown
    # Hand-written behavior modules, one per model that needs methods beyond
    # its attributes. Both the hand-written models and the schema-generated
    # classes prepend the same module, so behavior has a single source.
    module Behaviors
      autoload :AttributeList, 'coridoc/markdown/behaviors/attribute_list'
      autoload :Admonition, 'coridoc/markdown/behaviors/admonition'
      autoload :Document, 'coridoc/markdown/behaviors/document'
      autoload :Extension, 'coridoc/markdown/behaviors/extension'
      autoload :Heading, 'coridoc/markdown/behaviors/heading'
      autoload :Math, 'coridoc/markdown/behaviors/math'
      autoload :Text, 'coridoc/markdown/behaviors/text'
    end
  end
end
