# frozen_string_literal: true

require 'spec_helper'

# Guards the PM_TYPE vocabulary emitted by ceradoc-mirror against the
# canonical @metanorma/mirror (JS) vocabulary. When the JS library adds or
# renames a type, this spec forces an explicit decision here.
RSpec.describe 'JS library vocabulary conformance' do
  let(:js_mark_types) do
    %w[emphasis strong subscript superscript code underline strike
       smallcap link xref eref footnote stem concept bcp14 span]
  end

  let(:js_node_types) do
    %w[
      doc preface sections bibliography
      clause annex content_section abstract foreword introduction
      acknowledgements terms definitions references
      paragraph note admonition example sourcecode formula quote review
      bullet_list ordered_list list_item dl dt dd
      table table_head table_body table_foot table_row table_cell
      figure image
      footnotes footnote_marker footnote_entry
      text soft_break floating_title
    ]
  end

  describe 'Phase 1 renames (direct 1:1 mappings)' do
    it 'Bold emits "strong"' do
      expect(Ceradoc::Mirror::Mark::Bold.new.type).to eq('strong')
    end

    it 'Italic emits "emphasis"' do
      expect(Ceradoc::Mirror::Mark::Italic.new.type).to eq('emphasis')
    end

    it 'Strikethrough emits "strike"' do
      expect(Ceradoc::Mirror::Mark::Strikethrough.new.type).to eq('strike')
    end

    it 'CodeBlock emits "sourcecode"' do
      expect(Ceradoc::Mirror::Node::CodeBlock.new.type).to eq('sourcecode')
    end

    it 'Blockquote emits "quote"' do
      expect(Ceradoc::Mirror::Node::Blockquote.new.type).to eq('quote')
    end

    it 'DefinitionList emits "dl"' do
      expect(Ceradoc::Mirror::Node::DefinitionList.new.type).to eq('dl')
    end

    it 'DefinitionTerm emits "dt"' do
      expect(Ceradoc::Mirror::Node::DefinitionTerm.new.type).to eq('dt')
    end

    it 'DefinitionDescription emits "dd"' do
      expect(Ceradoc::Mirror::Node::DefinitionDescription.new.type).to eq('dd')
    end

    it 'Header emits "floating_title"' do
      expect(Ceradoc::Mirror::Node::Header.new.type).to eq('floating_title')
    end
  end

  describe 'Phase 1 renames do not leave stale strings behind' do
    let(:forbidden_mark_types) { %w[bold italic strikethrough] }
    let(:forbidden_node_types) do
      %w[code_block blockquote definition_list definition_term
         definition_description header]
    end

    it 'no Mark subclass emits a forbidden type' do
      emitted = Ceradoc::Mirror::Mark::TYPE_TO_CLASS.keys
      stale = forbidden_mark_types & emitted
      expect(stale).to be_empty,
                       "stale mark types still emitted: #{stale.inspect}"
    end

    it 'no Node subclass emits a forbidden type' do
      emitted = Ceradoc::Mirror::Node::TYPE_TO_CLASS.keys
      stale = forbidden_node_types & emitted
      expect(stale).to be_empty,
                       "stale node types still emitted: #{stale.inspect}"
    end
  end

  describe 'reverse direction recognizes the new vocabulary' do
    let(:reverse) { Ceradoc::Mirror::MirrorToCoreModel.new }

    it 'deserializes sourcecode back to SourceBlock' do
      mirror = Ceradoc::Mirror::Node::CodeBlock.new(
        attrs: Ceradoc::Mirror::Node::CodeBlock::Attrs.new(language: 'ruby'),
        content: [Ceradoc::Mirror::Node::Text.new(text: 'puts 1')]
      )
      core = reverse.call(Ceradoc::Mirror::Node::Document.new(content: [mirror]))
      expect(core.children.first).to be_a(Ceradoc::CoreModel::SourceBlock)
    end

    it 'deserializes strong mark back to BoldElement' do
      text_node = Ceradoc::Mirror::Node::Text.new(
        text: 'x', marks: [Ceradoc::Mirror::Mark::Bold.new]
      )
      para = Ceradoc::Mirror::Node::Paragraph.new(content: [text_node])
      core = reverse.call(Ceradoc::Mirror::Node::Document.new(content: [para]))
      inline = core.children.first.children.first
      expect(inline).to be_a(Ceradoc::CoreModel::BoldElement)
    end
  end

  describe 'Phase 2 structural containers (partition_structural: true)' do
    it 'Preamble PM_TYPE is "preface"' do
      expect(Ceradoc::Mirror::Node::Preamble.new.type).to eq('preface')
    end

    it 'Sections PM_TYPE is "sections"' do
      expect(Ceradoc::Mirror::Node::Sections.new.type).to eq('sections')
    end

    it 'does not partition by default (backward compat)' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'intro'),
          Ceradoc::CoreModel::SectionElement.new(title: 'S1', level: 1, children: []),
          Ceradoc::CoreModel::SectionElement.new(title: 'S2', level: 1, children: [])
        ]
      )
      mirror = Ceradoc::Mirror.transform(doc)
      types = mirror.content.map(&:type)
      expect(types).to eq(%w[paragraph section section])
    end

    it 'partitions into [preface, sections] when kwarg is set' do
      doc = Ceradoc::CoreModel::DocumentElement.new(
        children: [
          Ceradoc::CoreModel::ParagraphBlock.new(content: 'intro'),
          Ceradoc::CoreModel::SectionElement.new(title: 'S1', level: 1, children: []),
          Ceradoc::CoreModel::SectionElement.new(title: 'S2', level: 1, children: [])
        ]
      )
      mirror = Ceradoc::Mirror.transform(doc, partition_structural: true)
      types = mirror.content.map(&:type)
      expect(types).to eq(%w[preface sections])
      preface = mirror.content[0]
      sections = mirror.content[1]
      expect(preface.content.map(&:type)).to eq(%w[paragraph])
      expect(sections.content.map(&:type)).to eq(%w[clause clause])
    end

    it 'places footnotes block in trailing bucket' do
      footnotes = Ceradoc::Mirror::Node::Footnotes.new
      paragraph = Ceradoc::Mirror::Node::Paragraph.new(
        content: [Ceradoc::Mirror::Node::Text.new(text: 'x')]
      )
      # Simulate the post-extract state by partitioning directly.
      buckets = Ceradoc::Mirror::Partitioner.partition([paragraph, footnotes])
      expect(buckets[:trailing]).to eq([footnotes])
      expect(buckets[:preface]).to eq([paragraph])
    end
  end

  describe 'Phase 3 semantic section types' do
    it 'section handler emits "section" by default (backward compat)' do
      element = Ceradoc::CoreModel::SectionElement.new(title: 'S', level: 1)
      node = Ceradoc::Mirror::Handlers::Structural.section(
        element, context: Ceradoc::Mirror::CoreModelToMirror.new
      )
      expect(node.type).to eq('section')
    end

    it 'section handler emits "clause" when partition_structural is on' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::SectionElement.new(title: 'S', level: 1)
      node = Ceradoc::Mirror::Handlers::Structural.section(
        element, context: transformer
      )
      expect(node.type).to eq('clause')
    end

    it 'section handler maps style=appendix to annex' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      metadata = Ceradoc::CoreModel::Metadata.new
      metadata['style'] = 'appendix'
      element = Ceradoc::CoreModel::SectionElement.new(
        title: 'Appendix', level: 1, attributes: metadata
      )
      node = Ceradoc::Mirror::Handlers::Structural.section(
        element, context: transformer
      )
      expect(node.type).to eq('annex')
    end

    it 'partition recognizes clause/annex/etc as sections' do
      clause = Ceradoc::Mirror::Node::Section.new(
        type: 'clause',
        attrs: Ceradoc::Mirror::Node::Section::Attrs.new(title: 'C', level: 1)
      )
      annex = Ceradoc::Mirror::Node::Section.new(
        type: 'annex',
        attrs: Ceradoc::Mirror::Node::Section::Attrs.new(title: 'A', level: 1)
      )
      buckets = Ceradoc::Mirror::Partitioner.partition([clause, annex])
      expect(buckets[:sections].map(&:type)).to eq(%w[clause annex])
    end
  end

  describe 'Phase 4 sourcecode shape' do
    it 'sourcecode uses attrs.text and empty content when partition_structural' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::SourceBlock.new(
        content: "puts 'hi'", language: 'ruby'
      )
      node = Ceradoc::Mirror::Handlers::CodeBlock.source(
        element, context: transformer
      )
      expect(node.attrs.text).to eq("puts 'hi'")
      expect(node.content).to eq([])
      hash = node.to_hash
      expect(hash['attrs']['text']).to eq("puts 'hi'")
      expect(hash['content']).to be_nil.or eq([])
    end

    it 'sourcecode uses child text node when partition_structural is off (backward compat)' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      element = Ceradoc::CoreModel::SourceBlock.new(
        content: "puts 'hi'", language: 'ruby'
      )
      node = Ceradoc::Mirror::Handlers::CodeBlock.source(
        element, context: transformer
      )
      expect(node.attrs.text).to be_nil
      expect(node.content.length).to eq(1)
      expect(node.content.first.text).to eq("puts 'hi'")
    end

    it 'round-trips attrs.text back to SourceBlock content' do
      mirror = Ceradoc::Mirror::Node::CodeBlock.new(
        attrs: Ceradoc::Mirror::Node::CodeBlock::Attrs.new(
          language: 'ruby', text: "puts 'hi'"
        )
      )
      doc = Ceradoc::Mirror::Node::Document.new(content: [mirror])
      core = Ceradoc::Mirror::MirrorToCoreModel.new.call(doc)
      expect(core.children.first).to be_a(Ceradoc::CoreModel::SourceBlock)
      expect(core.children.first.content).to eq("puts 'hi'")
    end
  end

  describe 'Phase 4 admonition shape' do
    it 'emits attrs.type always (dialect-agnostic)' do
      element = Ceradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note', content: 'heads up'
      )
      node = Ceradoc::Mirror::Handlers::Admonition.call(
        element, context: Ceradoc::Mirror::CoreModelToMirror.new
      )
      hash = node.to_hash
      expect(hash['attrs']['type']).to eq('note')
      expect(hash['attrs']).not_to include('admonition_type')
    end

    it 'emits attrs.type regardless of partition_structural' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note', content: 'heads up'
      )
      node = Ceradoc::Mirror::Handlers::Admonition.call(
        element, context: transformer
      )
      hash = node.to_hash
      expect(hash['attrs']['type']).to eq('note')
      expect(hash['attrs']).not_to include('admonition_type')
    end

    it 'round-trips admonition back to AnnotationBlock' do
      mirror = Ceradoc::Mirror::Node::Admonition.new(
        attrs: Ceradoc::Mirror::Node::Admonition::Attrs.new(admonition_type: 'warning'),
        content: [Ceradoc::Mirror::Node::Text.new(text: 'careful')]
      )
      hash = mirror.to_hash
      expect(hash['attrs']).to include('type' => 'warning')
      expect(hash['attrs']).not_to include('admonition_type')

      rebuilt = Ceradoc::Mirror::Node::Admonition.from_hash(hash)
      expect(rebuilt.attrs.admonition_type).to eq('warning')

      doc = Ceradoc::Mirror::Node::Document.new(content: [rebuilt])
      core = Ceradoc::Mirror::MirrorToCoreModel.new.call(doc)
      expect(core.children.first).to be_a(Ceradoc::CoreModel::AnnotationBlock)
      expect(core.children.first.annotation_type).to eq('warning')
    end
  end

  describe 'Phase 4 figure wrapping' do
    it 'image is emitted bare by default (backward compat)' do
      element = Ceradoc::CoreModel::Image.new(src: 'a.png', title: 'My Fig')
      node = Ceradoc::Mirror::Handlers::Image.call(
        element, context: Ceradoc::Mirror::CoreModelToMirror.new
      )
      expect(node.type).to eq('image')
    end

    it 'wraps a titled image in figure when partition_structural' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::Image.new(src: 'a.png', title: 'My Fig')
      node = Ceradoc::Mirror::Handlers::Image.call(
        element, context: transformer
      )
      expect(node.type).to eq('figure')
      inner_types = node.content.map(&:type)
      expect(inner_types).to eq(%w[image caption])
    end

    it 'does not wrap an untitled image in figure' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::Image.new(src: 'a.png')
      node = Ceradoc::Mirror::Handlers::Image.call(
        element, context: transformer
      )
      expect(node.type).to eq('image')
    end

    it 'round-trips figure back to CoreModel::Image with caption' do
      transformer = Ceradoc::Mirror::CoreModelToMirror.new
      transformer.partition_structural = true
      element = Ceradoc::CoreModel::Image.new(src: 'a.png', title: 'My Fig')
      node = Ceradoc::Mirror::Handlers::Image.call(
        element, context: transformer
      )

      doc = Ceradoc::Mirror::Node::Document.new(content: [node])
      core = Ceradoc::Mirror::MirrorToCoreModel.new.call(doc)
      result = core.children.first
      expect(result).to be_a(Ceradoc::CoreModel::Image)
      expect(result.src).to eq('a.png')
      expect(result.caption).to eq('My Fig')
    end
  end
end
