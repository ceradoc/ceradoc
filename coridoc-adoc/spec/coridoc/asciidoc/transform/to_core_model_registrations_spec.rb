# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::ToCoreModelRegistrations do
  describe '.register_all!' do
    around do |ex|
      Coridoc::AsciiDoc::Transform::Registry.clear
      ex.run
      Coridoc::AsciiDoc::Transform::Registry.clear
      described_class.register_all!
      Coridoc::AsciiDoc::Transform::FromCoreModelRegistrations.register_all!
    end

    it 'registers Document transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::AsciiDoc::Model::Document
             )).to be true
    end

    it 'registers Section transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::AsciiDoc::Model::Section
             )).to be true
    end

    it 'registers Paragraph transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::AsciiDoc::Model::Paragraph
             )).to be true
    end

    it 'registers Block::Core transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::AsciiDoc::Model::Block::Core
             )).to be true
    end

    it 'registers specific block types with priority' do
      described_class.register_all!

      # Check that specific block types are registered
      [
        Coridoc::AsciiDoc::Model::Block::SourceCode,
        Coridoc::AsciiDoc::Model::Block::Quote,
        Coridoc::AsciiDoc::Model::Block::Example,
        Coridoc::AsciiDoc::Model::Block::Side,
        Coridoc::AsciiDoc::Model::Block::Literal,
        Coridoc::AsciiDoc::Model::Block::Open,
        Coridoc::AsciiDoc::Model::Block::Pass
      ].each do |block_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(block_class)).to be true
      end
    end

    it 'registers list types' do
      described_class.register_all!

      [
        Coridoc::AsciiDoc::Model::List::Unordered,
        Coridoc::AsciiDoc::Model::List::Ordered,
        Coridoc::AsciiDoc::Model::List::Definition
      ].each do |list_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(list_class)).to be true
      end
    end

    it 'registers inline element types' do
      described_class.register_all!

      [
        Coridoc::AsciiDoc::Model::Inline::Bold,
        Coridoc::AsciiDoc::Model::Inline::Italic,
        Coridoc::AsciiDoc::Model::Inline::Monospace,
        Coridoc::AsciiDoc::Model::Inline::Highlight,
        Coridoc::AsciiDoc::Model::Inline::Link
      ].each do |inline_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(inline_class)).to be true
      end
    end

    it 'registers other model types' do
      described_class.register_all!

      [
        Coridoc::AsciiDoc::Model::Table,
        Coridoc::AsciiDoc::Model::Term,
        Coridoc::AsciiDoc::Model::Admonition,
        Coridoc::AsciiDoc::Model::Image::BlockImage
      ].each do |model_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(model_class)).to be true
      end
    end

    context 'when transforming via registry' do
      it 'transforms Document using registered transformer' do
        described_class.register_all!

        doc = Coridoc::AsciiDoc::Model::Document.new(id: 'test-doc')
        result = Coridoc::AsciiDoc::Transform::Registry.transform(doc)

        expect(result).to be_a(Coridoc::CoreModel::DocumentElement)
        expect(result.id).to eq('test-doc')
      end

      it 'transforms Section using registered transformer' do
        described_class.register_all!

        title = Coridoc::AsciiDoc::Model::Title.new(content: 'Test Section')
        section = Coridoc::AsciiDoc::Model::Section.new(
          id: 'test-section',
          level: 1,
          title: title
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(section)

        expect(result).to be_a(Coridoc::CoreModel::SectionElement)
        expect(result.level).to eq(1)
      end

      it 'transforms Inline::Bold using registered transformer' do
        described_class.register_all!

        bold = Coridoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')
        result = Coridoc::AsciiDoc::Transform::Registry.transform(bold)

        expect(result).to be_a(Coridoc::CoreModel::BoldElement)
        expect(result.resolve_format_type).to eq('bold')
      end
    end

    context 'with custom transformer override' do
      it 'allows custom transformer to override default' do
        described_class.register_all!

        # Register a custom transformer that overrides the default
        custom_transformer = lambda { |model|
          Coridoc::CoreModel::InlineElement.new(
            format_type: 'custom-bold',
            content: "CUSTOM: #{model.content}"
          )
        }
        Coridoc::AsciiDoc::Transform::Registry.register(
          Coridoc::AsciiDoc::Model::Inline::Bold,
          custom_transformer
        )

        bold = Coridoc::AsciiDoc::Model::Inline::Bold.new(content: 'text')
        result = Coridoc::AsciiDoc::Transform::Registry.transform(bold)

        expect(result.format_type).to eq('custom-bold')
        expect(result.content).to eq('CUSTOM: text')
      end
    end
  end
end
