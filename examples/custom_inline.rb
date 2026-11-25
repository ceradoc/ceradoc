# frozen_string_literal: true

# Custom inline element examples for Ceradoc
#
# This file demonstrates how to create and use custom inline elements.

require_relative '../lib/ceradoc'

# Example 1: Create a custom highlight inline element
puts '=== Example 1: Create a custom highlight inline element ==='

# Define the custom inline class
module Ceradoc
  module Model
    module Inline
      class Highlight < Base
        attribute :text, :string
        attribute :color, :string, default: -> { 'yellow' }
      end
    end
  end
end

# Create a custom serializer
module Ceradoc
  module Output
    module Adoc
      module Serializers
        class HighlightSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "##{@model.text}#"
          end
        end
      end
    end
  end
end

# Register the serializer
Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Highlight,
  Ceradoc::Output::Adoc::Serializers::HighlightSerializer
)

# Use the custom inline element
highlight = Ceradoc::Model::Inline::Highlight.new
highlight.text = 'important text'

puts 'Custom highlight element:'
puts highlight.to_adoc
puts

# Example 2: Create a custom code inline element
puts '=== Example 2: Create a custom code inline element ==='

module Ceradoc
  module Model
    module Inline
      class Code < Base
        attribute :code, :string
        attribute :language, :string, default: -> { 'text' }
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class CodeSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "`#{@model.code}`"
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Code,
  Ceradoc::Output::Adoc::Serializers::CodeSerializer
)

code = Ceradoc::Model::Inline::Code.new
code.code = "puts 'Hello'"

puts 'Custom code element:'
puts code.to_adoc
puts

# Example 3: Create a custom mark inline element
puts '=== Example 3: Create a custom mark inline element ==='

module Ceradoc
  module Model
    module Inline
      class Mark < Base
        attribute :text, :string
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class MarkSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "##{@model.text}#"
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Mark,
  Ceradoc::Output::Adoc::Serializers::MarkSerializer
)

mark = Ceradoc::Model::Inline::Mark.new
mark.text = 'marked text'

puts 'Custom mark element:'
puts mark.to_adoc
puts

# Example 4: Create a custom keycap inline element
puts '=== Example 4: Create a custom keycap inline element ==='

module Ceradoc
  module Model
    module Inline
      class Keycap < Base
        attribute :key, :string
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class KeycapSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "kbd:[#{@model.key}]"
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Keycap,
  Ceradoc::Output::Adoc::Serializers::KeycapSerializer
)

keycap = Ceradoc::Model::Inline::Keycap.new
keycap.key = 'Ctrl'

puts 'Custom keycap element:'
puts keycap.to_adoc
puts

# Example 5: Use custom inline elements in a paragraph
puts '=== Example 5: Use custom inline elements in a paragraph ==='

paragraph = Ceradoc::Model::Paragraph.new
paragraph.content = [
  Ceradoc::Model::TextElement.new('Press '),
  Ceradoc::Model::Inline::Keycap.new(key: 'Ctrl'),
  Ceradoc::Model::TextElement.new(' + '),
  Ceradoc::Model::Inline::Keycap.new(key: 'C'),
  Ceradoc::Model::TextElement.new(' to copy, and '),
  Ceradoc::Model::Inline::Highlight.new(text: 'this is highlighted'),
  Ceradoc::Model::TextElement.new(' text.')
]

puts 'Paragraph with custom inline elements:'
puts paragraph.to_adoc
puts

# Example 6: Mix custom and built-in inline elements
puts '=== Example 6: Mix custom and built-in inline elements ==='

paragraph = Ceradoc::Model::Paragraph.new
paragraph.content = [
  Ceradoc::Model::TextElement.new('This has '),
  Ceradoc::Model::Inline::Bold.new(content: 'built-in bold'),
  Ceradoc::Model::TextElement.new(' and '),
  Ceradoc::Model::Inline::Highlight.new(text: 'custom highlight'),
  Ceradoc::Model::TextElement.new(' together.')
]

puts 'Mixed inline elements:'
puts paragraph.to_adoc
puts

# Example 7: Create a custom icon inline element
puts '=== Example 7: Create a custom icon inline element ==='

module Ceradoc
  module Model
    module Inline
      class Icon < Base
        attribute :icon_name, :string
        attribute :size, :string, default: -> { '1x' }
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class IconSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "icon:#{@model.icon_name}[size=#{@model.size}]"
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Icon,
  Ceradoc::Output::Adoc::Serializers::IconSerializer
)

icon = Ceradoc::Model::Inline::Icon.new
icon.icon_name = 'fire'
icon.size = '2x'

puts 'Custom icon element:'
puts icon.to_adoc
puts

# Example 8: Custom inline elements in document sections
puts '=== Example 8: Custom inline elements in document sections ==='

section = Ceradoc::Model::Section.new
section.title = Ceradoc::Model::Title.new
section.title.content = ['Keyboard Shortcuts']

paragraph = Ceradoc::Model::Paragraph.new
paragraph.content = [
  Ceradoc::Model::TextElement.new('Use '),
  Ceradoc::Model::Inline::Keycap.new(key: 'Ctrl'),
  Ceradoc::Model::TextElement.new(' + '),
  Ceradoc::Model::Inline::Keycap.new(key: 'S'),
  Ceradoc::Model::TextElement.new(' to save your work.')
]
section.blocks = [paragraph]

puts 'Section with custom inline elements:'
puts section.to_adoc
puts

# Example 9: Create a menu inline element
puts '=== Example 9: Create a menu inline element ==='

module Ceradoc
  module Model
    module Inline
      class Menu < Base
        attribute :menu_path, :string
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class MenuSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "menu:#{@model.menu_path}[]"
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Inline::Menu,
  Ceradoc::Output::Adoc::Serializers::MenuSerializer
)

menu = Ceradoc::Model::Inline::Menu.new
menu.menu_path = 'File[Save]'

puts 'Custom menu element:'
puts menu.to_adoc
puts

puts '=== All examples completed ==='
