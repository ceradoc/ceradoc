# frozen_string_literal: true

# Coridoc - Canonical Document Model and Transformation Hub
#
# Coridoc provides a hub-and-spoke architecture for document transformations.
# The CoreModel serves as the canonical, format-agnostic representation,
# enabling transformations between AsciiDoc, HTML, Markdown, DOCX, and more.
#
# @example Converting between formats
#   require 'coridoc'
#   html = Coridoc.convert("# Hello", from: :markdown, to: :html)
#
# @example Parsing and serializing
#   doc = Coridoc.parse("# Title\n\nContent", format: :markdown)
#   html = Coridoc.serialize(doc, to: :html)
#
# @example File-based conversion
#   doc = Coridoc.parse_file("input.md")
#   html = Coridoc.convert_file("input.md", to: :html)
#
# @example Manipulating documents
#   doc = Coridoc.parse(text, format: :asciidoc)
#   html = Coridoc.serialize(doc, to: :html)
#
# @example Building documents programmatically
#   doc = Coridoc.build do |d|
#     d.title = "My Document"
#     d.children << Coridoc::CoreModel::ParagraphBlock.new(content: "Hello")
#   end
#   Coridoc.serialize(doc, to: :html)

require_relative 'coridoc/coridoc'

module Coridoc
  autoload :VERSION, 'coridoc/version'
  autoload :CLI, 'coridoc/cli'
  autoload :Visitor, 'coridoc/visitor'
  autoload :BindingInflater, 'coridoc/binding_inflater'
  autoload :LinkRewriter, 'coridoc/link_rewriter'
  autoload :RelativePath, 'coridoc/relative_path'
end
