# frozen_string_literal: true

require 'spec_helper'

# ceradoc/ceradoc#320 + #298: inline links must survive the parse into
# CoreModel LinkElements (not flatten to raw markdown text) and must
# serialize to AsciiDoc link syntax on the way out.
RSpec.describe 'Markdown inline links' do
  let(:source) do
    "See [the manual](https://example.com/manual) and [relative](other.md) links.\n"
  end

  def paragraph_children
    core = Ceradoc.parse(source, format: :markdown)
    para = nil
    walker = lambda do |node, depth|
      return if para || node.nil?

      if node.is_a?(Ceradoc::CoreModel::ParagraphBlock)
        para = node
      elsif node.respond_to?(:children) && depth < 4
        Array(node.children).each { |c| walker.call(c, depth + 1) }
      end
    end
    walker.call(core, 0)
    para.children
  end

  it 'parses inline links into CoreModel::LinkElement children' do
    links = paragraph_children.grep(Ceradoc::CoreModel::LinkElement)
    expect(links.map(&:target)).to eq(['https://example.com/manual', 'other.md'])
    expect(links.map(&:content)).to eq(['the manual', 'relative'])
  end

  it 'keeps surrounding prose as TextContent between the links' do
    texts = paragraph_children.grep(Ceradoc::CoreModel::TextContent)
    expect(texts.first.text).to start_with('See ')
    expect(texts.map(&:text).join).to include('links.')
  end

  it 'serializes md links to AsciiDoc link syntax (#298)' do
    core = Ceradoc.parse(source, format: :markdown)
    adoc = Ceradoc.serialize(core, to: :asciidoc)
    expect(adoc).to include('https://example.com/manual[the manual]')
    expect(adoc).to include('link:other.md[relative]')
    expect(adoc).not_to include('[the manual](https://example.com/manual)')
  end

  it 'round-trips md links through the core model unchanged' do
    core = Ceradoc.parse(source, format: :markdown)
    md = Ceradoc.serialize(core, to: :markdown)
    expect(md).to include('[the manual](https://example.com/manual)')
    expect(md).to include('[relative](other.md)')
  end

  it 'flattens link nodes back to markdown syntax in text-only contexts' do
    node = { link: { link_text: 'x', link_url: 'https://e.co' } }
    expect(
      Ceradoc::Markdown::Bindings::Captures.flatten_inline_text([node])
    ).to eq('[x](https://e.co)')
  end
end
