# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::ElementTransformers::DocumentTransformer do
  describe '.transform_document' do
    it 'transforms a document with title and attributes' do
      header = Coridoc::AsciiDoc::Model::Header.new(
        title: Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'My Document')])
      )

      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Content')]
      )

      doc = Coridoc::AsciiDoc::Model::Document.new(
        id: 'doc-1',
        header: header,
        sections: [para]
      )

      # We mock the attribute extraction since ToCoreModel might not have a proper Document with attribute lists
      # Wait, no doubles! We just let ToCoreModel.extract_document_attributes run.

      result = described_class.transform_document(doc)

      expect(result).to be_a(Coridoc::CoreModel::DocumentElement)
      expect(result.id).to eq('doc-1')
      expect(result.title).to eq('My Document')
      # The document title is the canonical source of truth on
      # DocumentElement#title AND is emitted as a level-0 HeaderElement
      # at the top of the body so renderers that walk children see the
      # H1 (the standard ProseMirror/HTML rendering pattern). The
      # FromCoreModel Document transformer consumes the HeaderElement
      # when building Model::Header so AsciiDoc round-trip does not
      # double-render it as a floating_title section.
      expect(result.children.size).to eq(2)
      expect(result.children[0]).to be_a(Coridoc::CoreModel::HeaderElement)
      expect(result.children[0].level).to eq(0)
      expect(result.children[0].title).to eq('My Document')
      expect(result.children[1]).to be_a(Coridoc::CoreModel::ParagraphBlock)
      expect(result.children[1].content).to eq('Content')
    end

    it 'handles a document without header' do
      doc = Coridoc::AsciiDoc::Model::Document.new(
        sections: [],
        contents: []
      )

      result = described_class.transform_document(doc)

      expect(result).to be_a(Coridoc::CoreModel::DocumentElement)
      expect(result.title).to eq('')
      expect(result.children).to be_empty
    end
  end

  describe '.transform_section' do
    it 'transforms a section with title and nested contents' do
      para = Coridoc::AsciiDoc::Model::Paragraph.new(
        content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Section Content')]
      )

      title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Section One')])

      section = Coridoc::AsciiDoc::Model::Section.new(
        id: 'sec-1',
        level: 1,
        title: title,
        contents: [para],
        sections: []
      )

      result = described_class.transform_section(section)

      expect(result).to be_a(Coridoc::CoreModel::SectionElement)
      expect(result.id).to eq('sec-1')
      expect(result.title).to eq('Section One')
      expect(result.level).to eq(1)
      expect(result.children.size).to eq(1)
      expect(result.children[0]).to be_a(Coridoc::CoreModel::ParagraphBlock)
    end

    it 'transforms a section with nested sections and generates id' do
      inner_title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Inner')])
      inner_section = Coridoc::AsciiDoc::Model::Section.new(
        level: 2,
        title: inner_title,
        contents: [],
        sections: []
      )

      outer_title = Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Outer')])
      outer_section = Coridoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: outer_title,
        contents: [],
        sections: [inner_section]
      )

      result = described_class.transform_section(outer_section)

      expect(result).to be_a(Coridoc::CoreModel::SectionElement)
      expect(result.title).to eq('Outer')
      # ID is generated if nil
      expect(result.id).to eq('_outer')
      expect(result.children.size).to eq(1)

      inner_core = result.children[0]
      expect(inner_core).to be_a(Coridoc::CoreModel::SectionElement)
      expect(inner_core.title).to eq('Inner')
      expect(inner_core.id).to eq('_outer_inner')
    end

    it 'propagates [appendix] style into CoreModel attributes' do
      list = Coridoc::AsciiDoc::Model::AttributeList.new
      list.add_positional('appendix')
      section = Coridoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Appendix')]),
        attribute_list: list
      )

      result = described_class.transform_section(section)

      expect(result.attributes).to be_a(Coridoc::CoreModel::Metadata)
      expect(result.attributes['style']).to eq('appendix')
    end

    it 'propagates named role into CoreModel attributes' do
      list = Coridoc::AsciiDoc::Model::AttributeList.new
      list.add_named('role', 'summary')
      section = Coridoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Overview')]),
        attribute_list: list
      )

      result = described_class.transform_section(section)

      expect(result.attributes['role']).to eq('summary')
    end

    it 'leaves attributes nil when section has no attribute list' do
      section = Coridoc::AsciiDoc::Model::Section.new(
        level: 1,
        title: Coridoc::AsciiDoc::Model::Title.new(content: [Coridoc::AsciiDoc::Model::TextElement.new(content: 'Plain')])
      )

      expect(described_class.transform_section(section).attributes).to be_nil
    end
  end
end
