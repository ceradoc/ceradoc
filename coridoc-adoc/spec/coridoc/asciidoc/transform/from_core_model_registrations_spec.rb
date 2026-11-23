# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::Transform::FromCoreModelRegistrations do
  describe '.register_all!' do
    around do |ex|
      Coridoc::AsciiDoc::Transform::Registry.clear
      ex.run
      Coridoc::AsciiDoc::Transform::Registry.clear
      Coridoc::AsciiDoc::Transform::ToCoreModelRegistrations.register_all!
      described_class.register_all!
    end

    it 'registers StructuralElement transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::CoreModel::StructuralElement
             )).to be true
    end

    it 'registers Block transformer' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::CoreModel::Block
             )).to be true
    end

    it 'registers AnnotationBlock with priority (before Block)' do
      described_class.register_all!

      expect(Coridoc::AsciiDoc::Transform::Registry.registered?(
               Coridoc::CoreModel::AnnotationBlock
             )).to be true
    end

    it 'registers list types' do
      described_class.register_all!

      [
        Coridoc::CoreModel::ListBlock,
        Coridoc::CoreModel::ListItem
      ].each do |list_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(list_class)).to be true
      end
    end

    it 'registers other model types' do
      described_class.register_all!

      [
        Coridoc::CoreModel::Table,
        Coridoc::CoreModel::Term,
        Coridoc::CoreModel::InlineElement,
        Coridoc::CoreModel::Image
      ].each do |model_class|
        expect(Coridoc::AsciiDoc::Transform::Registry.registered?(model_class)).to be true
      end
    end

    context 'when transforming via registry' do
      it 'transforms StructuralElement document using registered transformer' do
        described_class.register_all!

        doc = Coridoc::CoreModel::DocumentElement.new(
          id: 'test-doc',
          title: 'Test Document'
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(doc)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Document)
        expect(result.id).to eq('test-doc')
      end

      it 'transforms StructuralElement section using registered transformer' do
        described_class.register_all!

        section = Coridoc::CoreModel::SectionElement.new(
          id: 'test-section',
          level: 1,
          title: 'Test Section'
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(section)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Section)
        expect(result.level).to eq(1)
      end

      it 'transforms InlineElement using registered transformer' do
        described_class.register_all!

        inline = Coridoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Bold)
        expect(result.content).to eq('bold text')
      end

      it 'transforms AnnotationBlock with correct priority' do
        described_class.register_all!

        annotation = Coridoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'note',
          content: 'This is a note'
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(annotation)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Admonition)
        expect(result.type).to eq('NOTE')
      end
    end

    context 'with custom transformer override' do
      it 'allows custom transformer to override default' do
        described_class.register_all!

        # Register a custom transformer that overrides the default
        custom_transformer = lambda { |model|
          Coridoc::AsciiDoc::Model::Inline::Italic.new(
            content: "CUSTOM: #{model.content}"
          )
        }
        Coridoc::AsciiDoc::Transform::Registry.register(
          Coridoc::CoreModel::InlineElement,
          custom_transformer
        )

        inline = Coridoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'text'
        )
        result = Coridoc::AsciiDoc::Transform::Registry.transform(inline)

        expect(result).to be_a(Coridoc::AsciiDoc::Model::Inline::Italic)
        expect(result.content).to eq('CUSTOM: text')
      end
    end
  end
end
