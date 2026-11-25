# frozen_string_literal: true

# The SDK is an optional output dependency, absent from generic frontend CI.
if ENV['CERADOC_METANORMA_TEST'] == '1'
  require 'ceradoc/metanorma'
  require 'metanorma/iso/document'
  require 'ceradoc/asciidoc'
  require 'ceradoc/markdown'
  require 'ceradoc/markdown/metanorma_input'
  require 'nokogiri'

  RSpec.describe Ceradoc::Metanorma::Builder do
    let(:core_models) { Ceradoc::CoreModel }

    def document(*children)
      core_models::DocumentElement.new(title: 'Example', children: children)
    end

    def xml(model)
      Nokogiri::XML(model.to_xml).remove_namespaces!
    end

    it 'constructs the actual SDK semantic root without parsing XML' do
      allow(Metanorma::Standoc::Document::Root).to receive(:from_xml).and_call_original
      root = described_class.build(document(core_models::ParagraphBlock.new(content: 'Text')))
      expect(root).to be_a(Metanorma::Standoc::Document::Root)
      expect(root.sections.clause.first.paragraphs.first).to be_a(Metanorma::Document::Components::Paragraphs::ParagraphBlock)
      expect(root.type).to eq('semantic')
      expect(Metanorma::Standoc::Document::Root).not_to have_received(:from_xml)
    end

    it 'preserves mixed inline order including nested formatting' do
      children = [
        core_models::TextContent.new(text: 'A '),
        core_models::BoldElement.new(children: [core_models::TextContent.new(text: 'bold '), core_models::ItalicElement.new(content: 'nested')]),
        core_models::TextContent.new(text: ' Z')
      ]
      p = core_models::ParagraphBlock.new(children: children)
      out = xml(described_class.build(document(p)))
      expect(out.at_xpath('//p').inner_html).to eq('A <strong>bold <em>nested</em></strong> Z')
    end

    it 'preserves authored IDs and xref targets' do
      p = core_models::ParagraphBlock.new(id: 'authored', children: [core_models::CrossReferenceElement.new(target: 'scope', content: 'Scope')])
      out = xml(described_class.build(document(core_models::SectionElement.new(id: 'scope', title: 'Scope', children: [p]))))
      expect(out.at_xpath('//p')['id']).to eq('authored')
      expect(out.at_xpath('//xref')['target']).to eq('scope')
    end

    it 'does not mutate its input and generates stable unique IDs' do
      input = document(core_models::ParagraphBlock.new(content: 'a'), core_models::ParagraphBlock.new(content: 'b'))
      before = input.to_json
      first = described_class.build(input).to_xml
      expect(described_class.build(input).to_xml).to eq(first)
      expect(input.to_json).to eq(before)
      ids = xml(described_class.build(input)).xpath('//*[@id]').map { |n| n['id'] }
      expect(ids.uniq).to eq(ids)
    end

    it 'rejects duplicate authored IDs' do
      expect { described_class.build(document(core_models::ParagraphBlock.new(id: 'x'), core_models::ParagraphBlock.new(id: 'x'))) }.to raise_error(ArgumentError, /Duplicate authored ID/)
    end

    it 'builds flat headings and existing nested structure without synthetic inner clauses' do
      input = document(
        core_models::SectionElement.new(title: 'A', level: 1, children: [core_models::ParagraphBlock.new(content: 'a')]),
        core_models::SectionElement.new(title: 'B', level: 2), core_models::ParagraphBlock.new(content: 'b')
      )
      out = xml(described_class.build(input))
      expect(out.xpath('//sections/clause').size).to eq(1)
      expect(out.xpath('//sections/clause/p').text).to eq('a')
      expect(out.xpath('//sections/clause/clause/p').text).to eq('b')
    end

    it 'builds ordered and nested unordered lists with mixed item text' do
      inner = core_models::ListBlock.new(marker_type: 'unordered', items: [core_models::ListItem.new(content: 'Nested')])
      outer = core_models::ListBlock.new(marker_type: 'ordered', start: 3, items: [core_models::ListItem.new(children: [core_models::TextContent.new(text: 'One '), core_models::BoldElement.new(content: 'bold')], nested_list: inner)])
      out = xml(described_class.build(document(outer)))
      expect(out.at_xpath('//ol')['start']).to eq('3')
      expect(out.at_xpath('//ol/li/p/strong').text).to eq('bold')
      expect(out.at_xpath('//ol/li/ul/li/p').text).to eq('Nested')
    end

    it 'builds tables with spans and header cells' do
      table = core_models::Table.new(title: 'Data', rows: [core_models::TableRow.new(cells: [core_models::TableCell.new(content: 'Head', header: true, colspan: 2), core_models::TableCell.new(content: 'Body')])])
      out = xml(described_class.build(document(table)))
      expect(out.at_xpath('//table/name').text).to eq('Data')
      expect(out.at_xpath('//th')['colspan']).to eq('2')
      expect(out.at_xpath('//td').text).to eq('Body')
    end

    it 'builds figures, source code, notes and math as typed blocks' do
      input = document(
        core_models::Image.new(src: 'diagram.svg', alt: 'Diagram', caption: 'Caption'),
        core_models::SourceBlock.new(language: 'ruby', content: 'puts "hi"'),
        core_models::AnnotationBlock.new(annotation_type: 'note', content: 'A note'),
        core_models::StemBlock.new(language: 'latex', content: 'x^2')
      )
      out = xml(described_class.build(input))
      expect(out.at_xpath('//figure/image')['src']).to eq('diagram.svg')
      expect(out.at_xpath('//sourcecode')['lang']).to eq('ruby')
      expect(out.at_xpath('//note/p').text).to eq('A note')
      expect(out.at_xpath('//formula/stem/latexmath').text).to eq('x^2')
    end

    it 'fails closed with a node path for unsupported content' do
      expect { described_class.build(document(core_models::PassBlock.new(content: '<raw/>'))) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, %r{PassBlock at document/0})
    end

    it 'rejects unknown source formats and non-document input' do
      expect { described_class.parse('a', format: :rtf) }.to raise_error(ArgumentError, /Unsupported source/)
      expect { described_class.build(core_models::ParagraphBlock.new) }.to raise_error(ArgumentError, /DocumentElement/)
    end

    it 'round trips the constructed SDK graph through XML' do
      root = described_class.build(document(core_models::ParagraphBlock.new(children: [core_models::TextContent.new(text: 'a '), core_models::BoldElement.new(content: 'b'), core_models::TextContent.new(text: ' c')])))
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
      input = document(core_models::ParagraphBlock.new(content: 'generated'), core_models::ParagraphBlock.new(id: '_ceradoc_paragraphblock_1', content: 'authored'))
      out = xml(described_class.build(input))
      expect(out.xpath('//p').map { |n| n['id'] }).to eq(%w[_ceradoc_paragraphblock_1_ _ceradoc_paragraphblock_1])
    end

    it 'maps supported frontmatter metadata and rejects unknown fields' do
      front = core_models::FrontmatterBlock::Codec.from_hash({ 'docnumber' => '123', 'docidentifier' => 'STD 123', 'language' => 'en' })
      root = described_class.build(document(front, core_models::ParagraphBlock.new(content: 'Text')))
      expect(root.bibdata.docnumber).to eq('123')
      expect(root.bibdata.docidentifier.first.id).to eq('STD 123')
      expect(xml(root).at_xpath('//bibdata/language').text).to eq('en')
      unknown = core_models::FrontmatterBlock::Codec.from_hash({ 'secret-new-field' => 'x' })
      expect { described_class.build(document(unknown)) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /secret-new-field/)
    end

    it 'maps bibliographic identities and reference text' do
      bibliography = core_models::Bibliography.new(title: 'References', entries: [core_models::BibliographyEntry.new(anchor_name: 'ref1', document_id: 'STD 123', ref_text: 'A reference')])
      out = xml(described_class.build(document(bibliography)))
      expect(out.at_xpath('//bibliography/references/bibitem')['id']).to eq('ref1')
      expect(out.at_xpath('//bibliography//docidentifier').text).to eq('STD 123')
      expect(out.at_xpath('//bibliography//formattedref').text).to eq('A reference')
    end

    it 'fails closed for custom attributes, unknown math and source callouts' do
      p = core_models::ParagraphBlock.new(content: 'a', element_attributes: [core_models::ElementAttribute.new(name: 'custom', value: 'x')])
      expect { described_class.build(document(p)) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /element attributes/)
      expect { described_class.build(document(core_models::StemBlock.new(language: 'unknown', content: 'x'))) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /math language/)
      expect { described_class.build(document(core_models::InlineElement.new(format_type: 'unknown'))) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode)
    end

    it 'preserves an authored document identity without treating its title as a duplicate' do
      input = document(core_models::HeaderElement.new(level: 0, id: 'docid', title: 'Example'))
      input.id = 'docid'
      expect(described_class.build(input).bibdata.id).to eq('docid')
    end

    it 'preserves an explicitly empty Markdown image alternative text' do
      out = xml(described_class.parse("# Example\n\n![](diagram.svg)\n", format: :markdown))
      expect(out.at_xpath('//image')['alt'].to_s).to eq('')
    end

    it 'maps actual Markdown authored anchors and internal links to semantic cross references' do
      source = "# Example\n\n## Scope\n{: #scope}\n\nSee [](#method) and [chosen label](#method).\n\n## Method\n{: #method}\n\nBody.\n"
      out = xml(described_class.parse(source, format: :markdown))
      expect(out.xpath('//sections/clause/@id').map(&:value)).to eq(%w[scope method])
      expect(out.xpath('//xref/@target').map(&:value)).to eq(%w[method method])
      expect(out.xpath('//xref').map(&:text)).to eq(['', 'chosen label'])
      expect { described_class.parse("# Example\n\n## Scope\n{: .hidden}\n", format: :markdown) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /Markdown block/)
    end

    it 'preserves authored Markdown IDs and ordered-list starts in the optional adapter' do
      heading = Ceradoc::Markdown::Heading.new(id: 'authored', text: 'Scope', level: 2)
      core = Ceradoc::Markdown::MetanormaInput.transform(heading)
      expect(core.id).to eq('authored')
      list = Ceradoc::Markdown::List.new(ordered: true, start_number: 5)
      expect(Ceradoc::Markdown::MetanormaInput.transform(list).start).to eq(5)
      expect(Ceradoc::Markdown.to_core(heading).id).to be_nil
    end

    it 'preserves mathematical semantics in the optional Markdown adapter' do
      math = Ceradoc::Markdown::Math.new(content: 'x^2', inline: false)
      core = Ceradoc::Markdown::MetanormaInput.transform(math)
      expect(core).to be_a(core_models::StemBlock)
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
      expect { described_class.parse("# Example\n\n[link](url \"title\")\n", format: :markdown) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode)
      expect { described_class.parse("# Example\n\n{::unknown /}\n", format: :markdown) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /markdown_extension/)
      expect { described_class.parse("= Example\n\n[pass]\n++++\n<raw/>\n++++\n", format: :asciidoc) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode)
    end

    it 'disambiguates generated section IDs while preserving explicit source anchors' do
      source = "= Example\n\n== Same\n\na\n\n== Same\n\nb\n"
      out = xml(described_class.parse(source, format: :asciidoc))
      expect(out.xpath('//sections/clause').map { |n| n['id'] }).to eq(%w[_same _same_])
      authored = xml(described_class.parse("= Example\n\n[[chosen]]\n== Scope\n\na\n", format: :asciidoc))
      expect(authored.at_xpath('//sections/clause')['id']).to eq('chosen')
    end

    it 'builds definition lists and ordered term-description pairs' do
      input = core_models::DefinitionList.new(items: [core_models::DefinitionItem.new(id: 'term1', term: 'First', definitions: ['Meaning one']), core_models::DefinitionItem.new(term: 'Second', definitions: ['Meaning two'])])
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

    it 'preserves string-only preambles and paragraphs represented as source lines' do
      input = document(core_models::PreambleElement.new(id: 'intro', content: 'Preamble text'), core_models::ParagraphBlock.new(lines: ['line one', 'line two']))
      out = xml(described_class.build(input))
      expect(out.at_xpath('//p[@id="intro"]').text).to eq('Preamble text')
      expect(out.xpath('//p').last.text).to eq("line one\nline two")
    end

    it 'rejects body content hidden in document/title fields and malformed source metadata' do
      input = document
      input.content = 'hidden body'
      expect { described_class.build(input) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /string document body/)
      title = core_models::HeaderElement.new(level: 0, title: 'Example', children: [core_models::ParagraphBlock.new(content: 'hidden')])
      expect { described_class.build(document(title)) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /body children/)
      source = "---\nkey: [\n---\n# Example\n\nText\n"
      expect { described_class.parse(source, format: :markdown) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /malformed source frontmatter/)
    end

    it 'constructs actual ISO root, metadata and section types directly from source' do
      root_class = Metanorma::Iso::Document::Root
      allow(root_class).to receive(:from_xml).and_call_original
      fixture = File.read(File.join(__dir__, 'fixtures', 'semantic-metadata.adoc'))
      root = described_class.parse(fixture, format: :asciidoc, root_class: root_class)
      expect(root).to be_a(root_class)
      expect(root).not_to be_a(Metanorma::Document::Root)
      expect(root.bibdata).to be_a(Metanorma::Iso::Document::Metadata::IsoBibliographicItem)
      expect(root.sections).to be_a(Metanorma::Iso::Document::Sections::IsoSections)
      expect(root.sections.clause.first).to be_a(Metanorma::Iso::Document::Sections::IsoClauseSection)
      expect(root.sections.clause.first.type).to eq('scope')
      expect(root.bibdata.doc_identifier.first.value).to eq('STD 123')
      expect(root.bibdata.titles.items.first.value).to eq('Example')
      expect(root_class).not_to have_received(:from_xml)
    end

    describe 'flavor roots that do not inherit the SDK or ISO root' do
      let(:fixture) { File.read(File.join(__dir__, 'fixtures', 'semantic-metadata.adoc')) }

      def flavor_root(sections_type:, bibdata_type:, collection:)
        Class.new(Lutaml::Model::Serializable) do
          attribute :type, :string
          attribute :flavor, :string
          attribute :bibdata, bibdata_type
          attribute :sections, sections_type, collection: collection
        end
      end

      it 'builds an ISO-vocabulary flavor root (IEC style) with the ISO builder' do
        iso = Metanorma::Iso::Document
        stub_const('Metanorma::Fancy::Document::Root',
                   flavor_root(sections_type: iso::Sections::IsoSections,
                               bibdata_type: iso::Metadata::IsoBibliographicItem, collection: false))
        root = described_class.parse(fixture, format: :asciidoc, root_class: Metanorma::Fancy::Document::Root)
        expect(root).to be_a(Metanorma::Fancy::Document::Root)
        expect(root.flavor).to eq('fancy')
        expect(root.sections).to be_a(iso::Sections::IsoSections)
        expect(root.bibdata.doc_identifier.first.value).to eq('STD 123')
      end

      it 'wraps the single built Sections when the root declares a sections collection (generic style)' do
        std = Metanorma::Standoc::Document
        stub_const('Metanorma::Plain::Document::Root',
                   flavor_root(sections_type: std::Sections::Sections,
                               bibdata_type: Metanorma::Document::Components::BibData::BibliographicItem,
                               collection: true))
        root = described_class.parse(fixture, format: :asciidoc, root_class: Metanorma::Plain::Document::Root)
        expect(root.sections).to be_an(Array)
        expect(root.sections.first).to be_a(std::Sections::Sections)
        expect(root.sections.first.clause.first).not_to be_nil
      end

      it 'still rejects classes that are not roots' do
        expect { described_class.build(document, root_class: String) }
          .to raise_error(ArgumentError, /native SDK Root/)
      end
    end

    it 'produces identical ISO native artifacts from the two real source frontends' do
      fixtures = File.join(__dir__, 'fixtures')
      root_class = Metanorma::Iso::Document::Root
      adoc = described_class.parse(File.read(File.join(fixtures, 'semantic-metadata.adoc')), format: :asciidoc, root_class: root_class)
      markdown = described_class.parse(File.read(File.join(fixtures, 'semantic-metadata.md')), format: :markdown, root_class: root_class)
      expect(markdown.to_xml).to eq(adoc.to_xml)
      expect(xml(adoc).at_xpath('//p/strong').text).to eq('world')
    end

    it 'keeps a nested clause named Scope distinct from the top-level ISO Scope' do
      nested = core_models::SectionElement.new(title: 'Scope', children: [core_models::ParagraphBlock.new(content: 'Nested body')])
      parent = core_models::SectionElement.new(title: 'Method', children: [nested])
      root = described_class.build(document(parent), root_class: Metanorma::Iso::Document::Root)
      expect(root.sections.clause.first.type).to be_nil
      expect(root.sections.clause.first.clause.first.type).to be_nil
    end

    it 'preserves authored ISO section anchors and rejects unrepresentable root anchors' do
      root_class = Metanorma::Iso::Document::Root
      core = document(core_models::SectionElement.new(id: 'authored', title: 'Scope', children: [core_models::ParagraphBlock.new(content: 'Body')]))
      root = described_class.build(core, root_class: root_class)
      expect(root.sections.clause.first.id).to eq('authored')
      core.id = 'document-anchor'
      expect { described_class.build(core, root_class: root_class) }.to raise_error(Ceradoc::Metanorma::UnsupportedNode, /document anchor/)
    end

    it 'keeps automatic source xrefs empty and preserves explicitly authored labels' do
      source = "= Example\n:mn-document-class: iso\n:doctype: international-standard\n\n[[scope]]\n== Scope\n\nSee <<scope>> and <<scope,Authored>>.\n"
      root = described_class.parse(source, root_class: Metanorma::Iso::Document::Root)
      refs = root.sections.clause.first.paragraphs.first.xref
      expect(Array(refs.first.text)).to be_empty
      expect(refs.last.text).to eq(['Authored'])
      expect(root.bibdata.ext.doctype_element.first.value).to eq('international-standard')
      generic = Ceradoc::AsciiDoc.parse_to_core(source)
      expect(generic.children.grep(core_models::SectionElement).first.children.first.children.grep(core_models::CrossReferenceElement).first.content).to eq('scope')
    end
  end
else
  RSpec.describe 'Optional Metanorma semantic integration' do
    it 'runs when the SDK integration environment is selected' do
      skip 'Set CERADOC_METANORMA_TEST=1 with metanorma-document and metanorma-standoc installed'
    end
  end
end
