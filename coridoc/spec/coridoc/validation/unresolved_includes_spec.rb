# frozen_string_literal: true

require 'spec_helper'
require 'coridoc'

RSpec.describe 'Validation unresolved-include guard' do
  let(:doc_with_includes) do
    Coridoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc',
      children: [
        Coridoc::CoreModel::SectionElement.new(
          id: 'sec-a', title: 'A', level: 1,
          children: [
            Coridoc::CoreModel::Include.new(target: 'shared/common.adoc'),
            Coridoc::CoreModel::ParagraphBlock.new(
              content: 'x',
              children: [Coridoc::CoreModel::Include.new(target: 'shared/common.adoc')]
            )
          ]
        ),
        Coridoc::CoreModel::Include.new(target: 'other.adoc')
      ]
    )
  end

  let(:clean_doc) do
    Coridoc::CoreModel::DocumentElement.new(id: 'd', title: 'D', children: [])
  end

  # Non-model format helpers — Struct-based, allowed by project spec rules.
  let(:dropping_format) do
    Struct.new(:name) do
      def preserves_unresolved_includes?
        false
      end
    end.new(:htmlish)
  end

  let(:preserving_format) do
    Struct.new(:name) do
      def preserves_unresolved_includes?
        true
      end
    end.new(:adocish)
  end

  describe '.unresolved_include_targets' do
    it 'finds include targets anywhere in the tree, deduplicated' do
      expect(Coridoc::Validation.unresolved_include_targets(doc_with_includes))
        .to eq(%w[shared/common.adoc other.adoc])
    end

    it 'returns empty for a document without includes' do
      expect(Coridoc::Validation.unresolved_include_targets(clean_doc)).to eq([])
    end
  end

  describe '.guard_unresolved_includes!' do
    it 'raises UnresolvedIncludesError naming targets and the remediation' do
      expect do
        Coridoc::Validation.guard_unresolved_includes!(doc_with_includes, dropping_format)
      end.to raise_error(Coridoc::UnresolvedIncludesError, %r{shared/common\.adoc})
    end

    it 'points at resolve_includes in the message' do
      expect do
        Coridoc::Validation.guard_unresolved_includes!(doc_with_includes, dropping_format)
      end.to raise_error(Coridoc::UnresolvedIncludesError, /resolve_includes/)
    end

    it 'passes quietly for formats that preserve includes' do
      expect do
        Coridoc::Validation.guard_unresolved_includes!(doc_with_includes, preserving_format)
      end.not_to raise_error
    end

    it 'passes quietly when there are no includes' do
      expect do
        Coridoc::Validation.guard_unresolved_includes!(clean_doc, dropping_format)
      end.not_to raise_error
    end
  end
end
