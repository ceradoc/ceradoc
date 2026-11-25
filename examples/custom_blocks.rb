# frozen_string_literal: true

# Custom block type examples for Ceradoc
#
# This file demonstrates how to create and use custom block types.

require_relative '../lib/ceradoc'

# Example 1: Create a custom callout block
puts '=== Example 1: Create a custom callout block ==='

# Define the custom block class
module Ceradoc
  module Model
    module Block
      class Callout < Core
        attribute :delimiter_char, :string, default: -> { '!' }
        attribute :delimiter_len, :integer, default: -> { 4 }
        attribute :callout_type, :string, default: -> { 'info' }
      end
    end
  end
end

# Create a custom serializer
module Ceradoc
  module Output
    module Adoc
      module Serializers
        class CalloutSerializer < Core
          def serialize_to_adoc
            parts = []
            parts << @model.gen_delimiter << "\n"
            parts << @model.gen_title
            parts << @model.gen_attributes
            parts << @model.gen_lines
            parts << @model.gen_delimiter << "\n"
            parts.join
          end
        end
      end
    end
  end
end

# Register the serializer
Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Block::Callout,
  Ceradoc::Output::Adoc::Serializers::CalloutSerializer
)

# Use the custom block
callout = Ceradoc::Model::Block::Callout.new
callout.lines = ['This is an important callout!', 'Pay attention to this.']
callout.title = 'Important Note'

puts 'Custom callout block:'
puts callout.to_adoc
puts

# Example 2: Create a custom tip block
puts '=== Example 2: Create a custom tip block ==='

module Ceradoc
  module Model
    module Block
      class Tip < Core
        attribute :delimiter_char, :string, default: -> { '?' }
        attribute :delimiter_len, :integer, default: -> { 4 }
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class TipSerializer < Core
          def serialize_to_adoc
            parts = []
            parts << @model.gen_delimiter << "\n"
            parts << @model.gen_title
            parts << @model.gen_attributes
            parts << @model.gen_lines
            parts << @model.gen_delimiter << "\n"
            parts.join
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Block::Tip,
  Ceradoc::Output::Adoc::Serializers::TipSerializer
)

tip = Ceradoc::Model::Block::Tip.new
tip.lines = ["Here's a helpful tip:", 'Use Ceradoc for easy AsciiDoc processing.']

puts 'Custom tip block:'
puts tip.to_adoc
puts

# Example 3: Create a custom remark block
puts '=== Example 3: Create a custom remark block ==='

module Ceradoc
  module Model
    module Block
      class Remark < Core
        attribute :delimiter_char, :string, default: -> { 'R' }
        attribute :delimiter_len, :integer, default: -> { 4 }
      end
    end
  end
end

module Ceradoc
  module Output
    module Adoc
      module Serializers
        class RemarkSerializer < Core
          def serialize_to_adoc
            parts = []
            parts << @model.gen_delimiter << "\n"
            parts << @model.gen_title
            parts << @model.gen_attributes
            parts << @model.gen_lines
            parts << @model.gen_delimiter << "\n"
            parts.join
          end
        end
      end
    end
  end
end

Ceradoc::Output::Adoc::ElementRegistry.register(
  Ceradoc::Model::Block::Remark,
  Ceradoc::Output::Adoc::Serializers::RemarkSerializer
)

remark = Ceradoc::Model::Block::Remark.new
remark.title = 'Reviewer Remark'
remark.lines = ['This section needs clarification.', 'Please add more details.']

puts 'Custom remark block:'
puts remark.to_adoc
puts

# Example 4: Use custom blocks in a document
puts '=== Example 4: Use custom blocks in a document ==='

# Create a document with custom blocks
doc = Ceradoc::Model::Document.new
doc.header = Ceradoc::Model::Header.new
doc.header.title = 'Document with Custom Blocks'

section = Ceradoc::Model::Section.new
section.title = Ceradoc::Model::Title.new
section.title.content = ['Introduction']

# Add regular paragraph
para = Ceradoc::Model::Paragraph.new
para.content = [Ceradoc::Model::TextElement.new('This document contains custom block types.')]
section.blocks = [para]

# Add callout block
callout_block = Ceradoc::Model::Block::Callout.new
callout_block.lines = ['Important: Read this carefully!']
section.blocks << callout_block

# Add tip block
tip_block = Ceradoc::Model::Block::Tip.new
tip_block.title = 'Pro Tip'
tip_block.lines = ['Custom blocks make AsciiDoc more expressive.']
section.blocks << tip_block

doc.sections = [section]

puts 'Document with custom blocks:'
puts doc.to_adoc
puts

# Example 5: Custom block with attributes
puts '=== Example 5: Custom block with attributes ==='

callout_with_attrs = Ceradoc::Model::Block::Callout.new
callout_with_attrs.attributes = Ceradoc::Model::AttributeList.new
callout_with_attrs.attributes.add_named('id', 'callout1')
callout_with_attrs.attributes.add_named('role', 'important')
callout_with_attrs.lines = ['This callout has custom attributes.']

puts 'Custom block with attributes:'
puts callout_with_attrs.to_adoc
puts

# Example 6: Custom block with title
puts '=== Example 6: Custom block with title ==='

tip_with_title = Ceradoc::Model::Block::Tip.new
tip_with_title.title = 'Quick Tip'
tip_with_title.lines = ['Keep your custom blocks simple and focused.']

puts 'Custom block with title:'
puts tip_with_title.to_adoc
puts

puts '=== All examples completed ==='
