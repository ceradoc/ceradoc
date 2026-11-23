# frozen_string_literal: true

# The SDK is an optional output dependency, absent from generic frontend CI.
if ENV['CORIDOC_METANORMA_TEST'] == '1'
  require 'coridoc/metanorma'
  require 'coridoc/asciidoc'
  require 'coridoc/markdown'
  require 'coridoc/markdown/metanorma_input'
  require 'nokogiri'

  RSpec.describe Coridoc::Metanorma::Builder do
    C = Coridoc::CoreModel

    def document(*children)
      C::DocumentElement.new(title: 'Example', children: children)
    end

    def xml(model)
      Nokogiri::XML(model.to_xml).remove_namespaces!
    end

    it 'constructs the actual SDK semantic root without parsing XML' do
      expect(Metanorma::Standoc::Document::Root).not_to receive(:from_xml)
      root = described_class.build(document(C::ParagraphBlock.new(content: 'Text')))
      expect(root).to be_a(Metanorma::Standoc::Document::Root)
      expect(root.sections.clause.first.paragraphs.first).to be_a(Metanorma::Document::Components::Paragraphs::ParagraphBlock)
      expect(root.type).to eq('semantic')
    end

    it 'preserves mixed inline order including nested formatting' do
      p = C::ParagraphBlock.new(children: [C::TextContent.new(text: 'A '), C::BoldElement.new(children: [C::TextContent.new(text: 'bold '), C::ItalicElement.new(content: 'nested')]), C::TextContent.new(text: ' Z')])
      out = xml(described_class.build(document(p)))
      expect(out.at_xpath('//p').inner_html).to eq('A <strong>bold <em>nested</em></strong> Z')
    end

    it 'preserves authored IDs and xref targets' do
      p = C::ParagraphBlock.new(id: 'authored', children: [C::CrossReferenceElement.new(target: 'scope', content: 'Scope')])
      out = xml(described_class.build(document(C::SectionElement.new(id: 'scope', title: 'Scope', children: [p]))))
      expect(out.at_xpath('//p')['id']).to eq('authored')
      expect(out.at_xpath('//xref')['target']).to eq('scope')
    end

    it 'does not mutate its input and generates stable unique IDs' do
      input = document(C::ParagraphBlock.new(content: 'a'), C::ParagraphBlock.new(content: 'b'))
      before = input.to_json
      first = described_class.build(input).to_xml
      expect(described_class.build(input).to_xml).to eq(first)
      expect(input.to_json).to eq(before)
      ids = xml(described_class.build(input)).xpath('//*[@id]').map { |n| n['id'] }
      expect(ids.uniq).to eq(ids)
    end

    it 'rejects duplicate authored IDs' do
      expect { described_class.build(document(C::ParagraphBlock.new(id: 'x'), C::ParagraphBlock.new(id: 'x'))) }.to raise_error(ArgumentError, /Duplicate authored ID/)
    end

    it 'builds flat headings and existing nested structure without synthetic inner clauses' do
      input = document(C::SectionElement.new(title: 'A', level: 1, children: [C::ParagraphBlock.new(content: 'a')]), C::SectionElement.new(title: 'B', level: 2), C::ParagraphBlock.new(content: 'b'))
      out = xml(described_class.build(input))
      expect(out.xpath('//sections/clause').size).to eq(1)
      expect(out.xpath('//sections/clause/p').text).to eq('a')
      expect(out.xpath('//sections/clause/clause/p').text).to eq('b')
    end

    it 'builds ordered and nested unordered lists with mixed item text' do
      inner = C::ListBlock.new(marker_type: 'unordered', items: [C::ListItem.new(content: 'Nested')])
      outer = C::ListBlock.new(marker_type: 'ordered', start: 3, items: [C::ListItem.new(children: [C::TextContent.new(text: 'One '), C::BoldElement.new(content: 'bold')], nested_list: inner)])
      out = xml(described_class.build(document(outer)))
      expect(out.at_xpath('//ol')['start']).to eq('3')
      expect(out.at_xpath('//ol/li/p/strong').text).to eq('bold')
      expect(out.at_xpath('//ol/li/ul/li/p').text).to eq('Nested')
    end

    it 'builds tables with spans and header cells' do
      table = C::Table.new(title: 'Data', rows: [C::TableRow.new(cells: [C::TableCell.new(content: 'Head', header: true, colspan: 2), C::TableCell.new(content: 'Body')])])
      out = xml(described_class.build(document(table)))
      expect(out.at_xpath('//table/name').text).to eq('Data')
      expect(out.at_xpath('//th')['colspan']).to eq('2')
      expect(out.at_xpath('//td').text).to eq('Body')
    end

    it 'builds figures, source code, notes and math as typed blocks' do
      input = document(C::Image.new(src: 'diagram.svg', alt: 'Diagram', caption: 'Caption'), C::SourceBlock.new(language: 'ruby', content: 'puts "hi"'), C::AnnotationBlock.new(annotation_type: 'note', content: 'A note'), C::StemBlock.new(language: 'latex', content: 'x^2'))
      out = xml(described_class.build(input))
      expect(out.at_xpath('//figure/image')['src']).to eq('diagram.svg')
      expect(out.at_xpath('//sourcecode')['lang']).to eq('ruby')
      expect(out.at_xpath('//note/p').text).to eq('A note')
      expect(out.at_xpath('//formula/stem/latexmath').text).to eq('x^2')
    end

    it 'fails closed with a node path for unsupported content' do
      expect { described_class.build(document(C::PassBlock.new(content: '<raw/>'))) }.to raise_error(Coridoc::Metanorma::UnsupportedNode, /PassBlock at document\/0/)
    end

    it 'rejects unknown source formats and non-document input' do
      expect { described_class.parse('a', format: :rtf) }.to raise_error(ArgumentError, /Unsupported source/)
      expect { described_class.build(C::ParagraphBlock.new) }.to raise_error(ArgumentError, /DocumentElement/)
    end

    it 'round trips the constructed SDK graph through XML' do
      root = described_class.build(document(C::ParagraphBlock.new(children: [C::TextContent.new(text: 'a '), C::BoldElement.new(content: 'b'), C::TextContent.new(text: ' c')])))
      reparsed = root.class.from_xml(root.to_xml)
      expect(xml(reparsed).at_xpath('//p').inner_html).to eq('a <strong>b</strong> c')
    end

    it 'runs both real frontends through the same semantic contract' do
      adoc = described_class.parse("= Example\n\n== Scope\n\nHello *world*.\n", format: :asciidoc)
      md = described_class.parse("# Example\n\n## Scope\n\nHello **world**.\n", format: :markdown)
      a = xml(adoc)
      b = xml(md)
      expect(b.to_xml).to eq(a.to_xml)
    end
    it 'reserves authored IDs before generating colliding IDs' do
      input = document(C::ParagraphBlock.new(content: 'generated'), C::ParagraphBlock.new(id: '_coridoc_paragraphblock_1', content: 'authored'))
      out = xml(described_class.build(input))
      expect(out.xpath('//p').map { |n| n['id'] }).to eq(['_coridoc_paragraphblock_1_', '_coridoc_paragraphblock_1'])
    end

    it 'maps supported frontmatter metadata and rejects unknown fields' do
      front = C::FrontmatterBlock::Codec.from_hash({ 'docnumber' => '123', 'docidentifier' => 'STD 123', 'language' => 'en' })
      root = described_class.build(document(front, C::ParagraphBlock.new(content: 'Text')))
      expect(root.bibdata.docnumber).to eq('123')
      expect(root.bibdata.docidentifier.first.id).to eq('STD 123')
      expect(xml(root).at_xpath('//bibdata/language').text).to eq('en')
      unknown = C::FrontmatterBlock::Codec.from_hash({ 'secret-new-field' => 'x' })
      expect { described_class.build(document(unknown)) }.to raise_error(Coridoc::Metanorma::UnsupportedNode, /secret-new-field/)
    end

    it 'maps bibliographic identities and reference text' do
      bibliography = C::Bibliography.new(title: 'References', entries: [C::BibliographyEntry.new(anchor_name: 'ref1', document_id: 'STD 123', ref_text: 'A reference')])
      out = xml(described_class.build(document(bibliography)))
      expect(out.at_xpath('//bibliography/references/bibitem')['id']).to eq('ref1')
      expect(out.at_xpath('//bibliography//docidentifier').text).to eq('STD 123')
      expect(out.at_xpath('//bibliography//formattedref').text).to eq('A reference')
    end

    it 'fails closed for custom attributes, unknown math and source callouts' do
      p = C::ParagraphBlock.new(content: 'a', element_attributes: [C::ElementAttribute.new(name: 'custom', value: 'x')])
      expect { described_class.build(document(p)) }.to raise_error(Coridoc::Metanorma::UnsupportedNode, /element attributes/)
      expect { described_class.build(document(C::StemBlock.new(language: 'unknown', content: 'x'))) }.to raise_error(Coridoc::Metanorma::UnsupportedNode, /math language/)
      expect { described_class.build(document(C::InlineElement.new(format_type: 'unknown'))) }.to raise_error(Coridoc::Metanorma::UnsupportedNode)
    end

    it 'preserves an authored document identity without treating its title as a duplicate' do
      input = document(C::HeaderElement.new(level: 0, id: 'docid', title: 'Example'))
      input.id = 'docid'
      expect(described_class.build(input).bibdata.id).to eq('docid')
    end

    it 'preserves authored Markdown IDs and ordered-list starts in the optional adapter' do
      heading = Coridoc::Markdown::Heading.new(id: 'authored', text: 'Scope', level: 2)
      core = Coridoc::Markdown::MetanormaInput.transform(heading)
      expect(core.id).to eq('authored')
      list = Coridoc::Markdown::List.new(ordered: true, start_number: 5)
      expect(Coridoc::Markdown::MetanormaInput.transform(list).start).to eq(5)
      expect(Coridoc::Markdown.to_core(heading).id).to be_nil
    end

    it 'preserves mathematical semantics in the optional Markdown adapter' do
      math = Coridoc::Markdown::Math.new(content: 'x^2', inline: false)
      core = Coridoc::Markdown::MetanormaInput.transform(math)
      expect(core).to be_a(C::StemBlock)
      expect(xml(described_class.build(document(core))).at_xpath('//formula/stem/latexmath').text).to eq('x^2')
    end

    it 'produces identical XML from real multi-feature AsciiDoc and Markdown fixtures' do
      fixtures = File.join(__dir__, 'fixtures')
      a = described_class.parse(File.read(File.join(fixtures, 'semantic.adoc')), format: :asciidoc)
      b = described_class.parse(File.read(File.join(fixtures, 'semantic.md')), format: :markdown)
      expect(b.to_xml).to eq(a.to_xml)
      out = xml(a)
      %w[strong ul sourcecode table figure formula].each { |name| expect(out.at_xpath("//#{name}")).not_to be_nil }
    end

    it 'parses direct Markdown links, images and nested marks without flattening order' do
      root = described_class.parse("# Example\n\nSee [a **bold** label](https://example.com) and **bold *nested***.\n", format: :markdown)
      out = xml(root)
      expect(out.at_xpath('//link')['target']).to eq('https://example.com')
      expect(out.at_xpath('//link/strong').text).to eq('bold')
      expect(out.at_xpath('//p/strong/em').text).to eq('nested')
    end

    it 'rejects unrepresentable source syntax and unknown Markdown extensions' do
      expect { described_class.parse("# Example\n\n[link](url \"title\")\n", format: :markdown) }.to raise_error(Coridoc::Metanorma::UnsupportedNode)
      expect { described_class.parse("# Example\n\n{::unknown /}\n", format: :markdown) }.to raise_error(Coridoc::Metanorma::UnsupportedNode, /markdown_extension/)
      expect { described_class.parse("= Example\n\n[pass]\n++++\n<raw/>\n++++\n", format: :asciidoc) }.to raise_error(Coridoc::Metanorma::UnsupportedNode)
    end

    it 'disambiguates generated section IDs while preserving explicit source anchors' do
      source = "= Example\n\n== Same\n\na\n\n== Same\n\nb\n"
      out = xml(described_class.parse(source, format: :asciidoc))
      expect(out.xpath('//sections/clause').map { |n| n['id'] }).to eq(['_same', '_same_'])
      authored = xml(described_class.parse("= Example\n\n[[chosen]]\n== Scope\n\na\n", format: :asciidoc))
      expect(authored.at_xpath('//sections/clause')['id']).to eq('chosen')
    end

    it 'builds definition lists and ordered term-description pairs' do
      input = C::DefinitionList.new(items: [C::DefinitionItem.new(id: 'term1', term: 'First', definitions: ['Meaning one']), C::DefinitionItem.new(term: 'Second', definitions: ['Meaning two'])])
      out = xml(described_class.build(document(input)))
      expect(out.at_xpath('//dl').element_children.map(&:name)).to eq(%w[dt dd dt dd])
      expect(out.at_xpath('//dt')['id']).to eq('term1')
      expect(out.at_xpath('//dd/p').text).to eq('Meaning one')
    end

    it 'builds complete provided metadata from actual AsciiDoc attributes and Markdown frontmatter' do
      fixtures = File.join(__dir__, 'fixtures')
      a = described_class.parse(File.read(File.join(fixtures, 'semantic-metadata.adoc')), format: :asciidoc)
      b = described_class.parse(File.read(File.join(fixtures, 'semantic-metadata.md')), format: :markdown)
      expect(b.to_xml).to eq(a.to_xml)
      out = xml(a)
      expect(out.at_xpath('//bibdata/docnumber').text).to eq('123')
      expect(out.at_xpath('//bibdata/docidentifier').text).to eq('STD 123')
      expect(out.at_xpath('//bibdata/copyright/from').text).to eq('2026')
      expect(out.at_xpath('//bibdata/copyright/owner/organization/name').text).to eq('Example Organization')
    end

  end
else
  RSpec.describe 'Optional Metanorma semantic integration' do
    it 'runs when the SDK integration environment is selected' do
      skip 'Set CORIDOC_METANORMA_TEST=1 with metanorma-document and metanorma-standoc installed'
    end
  end
end
