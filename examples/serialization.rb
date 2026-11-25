# frozen_string_literal: true

# Serialization examples for Ceradoc
#
# This file demonstrates how to serialize Ceradoc document models to AsciiDoc.

require_relative '../lib/ceradoc'

# Example 1: Basic serialization
puts '=== Example 1: Basic serialization ==='
input = <<~ASCIIDOC
  = Document Title

  == Section 1

  This is a paragraph.
ASCIIDOC

doc = Ceradoc.parse(input)
output = doc.to_adoc

puts 'Serialized output:'
puts output
puts

# Example 2: Serialize individual elements
puts '=== Example 2: Serialize individual elements ==='

# Serialize a paragraph
paragraph = Ceradoc::Model::Paragraph.new
paragraph.content = [
  Ceradoc::Model::TextElement.new('This is a paragraph with '),
  Ceradoc::Model::Inline::Bold.new(content: 'bold text')
]
puts 'Paragraph:'
puts paragraph.to_adoc
puts

# Serialize a section
section = Ceradoc::Model::Section.new
section.title = Ceradoc::Model::Title.new
section.title.level_int = 2
section.title.content = ['Custom Section']
para = Ceradoc::Model::Paragraph.new
para.content = [Ceradoc::Model::TextElement.new('Section content')]
section.blocks = [para]
puts 'Section:'
puts section.to_adoc
puts

# Example 3: Serialize lists
puts '=== Example 3: Serialize lists ==='

# Unordered list
list = Ceradoc::Model::List::Unordered.new
item1 = Ceradoc::Model::ListItem.new
item1.content = [Ceradoc::Model::TextElement.new('First item')]
list.items << item1

item2 = Ceradoc::Model::ListItem.new
item2.content = [Ceradoc::Model::TextElement.new('Second item')]
list.items << item2

puts 'Unordered list:'
puts list.to_adoc
puts

# Ordered list
ordered = Ceradoc::Model::List::Ordered.new
item = Ceradoc::Model::ListItem.new
item.content = [Ceradoc::Model::TextElement.new('Step one')]
ordered.items << item

item = Ceradoc::Model::ListItem.new
item.content = [Ceradoc::Model::TextElement.new('Step two')]
ordered.items << item

puts 'Ordered list:'
puts ordered.to_adoc
puts

# Example 4: Serialize tables
puts '=== Example 4: Serialize tables ==='

table = Ceradoc::Model::Table.new

# Add header row
header_row = Ceradoc::Model::TableRow.new
%w[Name Age City].each do |header_text|
  cell = Ceradoc::Model::TableCell.new
  cell.content = [Ceradoc::Model::TextElement.new(header_text)]
  header_row.columns << cell
end
table.rows << header_row

# Add data row
data_row = Ceradoc::Model::TableRow.new
%w[Alice 25 NYC].each do |cell_text|
  cell = Ceradoc::Model::TableCell.new
  cell.content = [Ceradoc::Model::TextElement.new(cell_text)]
  data_row.columns << cell
end
table.rows << data_row

puts 'Table:'
puts table.to_adoc
puts

# Example 5: Serialize blocks
puts '=== Example 5: Serialize blocks ==='

# Listing block
listing = Ceradoc::Model::Block::Listing.new
listing.lines = ['def hello', "  puts 'Hello, World!'", 'end']
listing.attributes = Ceradoc::Model::AttributeList.new
listing.attributes.add_positional('ruby')
puts 'Listing block:'
puts listing.to_adoc
puts

# Quote block
quote = Ceradoc::Model::Block::Quote.new
quote.lines = ['This is a quote.', 'It spans multiple lines.']
puts 'Quote block:'
puts quote.to_adoc
puts

# Example 6: Serialize inline elements
puts '=== Example 6: Serialize inline elements ==='

# Create paragraph with various inline elements
paragraph = Ceradoc::Model::Paragraph.new
paragraph.content = [
  Ceradoc::Model::TextElement.new('Text with '),
  Ceradoc::Model::Inline::Bold.new(content: 'bold'),
  Ceradoc::Model::TextElement.new(', '),
  Ceradoc::Model::Inline::Italic.new(content: 'italic'),
  Ceradoc::Model::TextElement.new(', and '),
  Ceradoc::Model::Inline::Monospace.new(content: 'monospace'),
  Ceradoc::Model::TextElement.new(' text.')
]

puts 'Paragraph with inline elements:'
puts paragraph.to_adoc
puts

# Link
link = Ceradoc::Model::Inline::Link.new
link.path = 'https://example.com'
link.name = 'Example Site'
puts 'Link:'
puts "#{link.to_adoc}\n"
puts

# Anchor
anchor = Ceradoc::Model::Inline::Anchor.new
anchor.id = 'section1'
puts 'Anchor:'
puts "#{anchor.to_adoc}\n"
puts

# Example 7: Round-trip preservation
puts '=== Example 7: Round-trip preservation ==='
original = <<~ASCIIDOC
  = Document Title

  == Section One

  This is a paragraph with *bold* and _italic_ text.

  * List item 1
  * List item 2
ASCIIDOC

# Parse
doc1 = Ceradoc.parse(original)
# Serialize
serialized = doc1.to_adoc
# Parse again
doc2 = Ceradoc.parse(serialized)

puts "Original document title: #{doc1.header.title}"
puts "Re-parsed document title: #{doc2.header.title}"

# Both should have the same structure
puts "Original sections: #{doc1.sections.size}"
puts "Re-parsed sections: #{doc2.sections.size}"
puts

# Example 8: Using Ceradoc.convert
puts '=== Example 8: Using Ceradoc.convert ==='
doc = Ceradoc.parse("= Test\n\nContent")

# Convert to AsciiDoc (same as to_adoc)
output = Ceradoc.convert(doc, to: :adoc)
puts 'Converted output:'
puts output
puts

puts '=== All examples completed ==='
