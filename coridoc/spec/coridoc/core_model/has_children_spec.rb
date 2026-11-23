# frozen_string_literal: true

require 'spec_helper'

# Locks in the HasChildren predicate so downstream dispatch can rely on
# `is_a?(HasChildren)` instead of enumerating subclasses (OCP).
RSpec.describe Coridoc::CoreModel::HasChildren do
  # Classes that carry a +children+ collection and should satisfy
  # HasChildren — either directly (StructuralElement) or transitively
  # via ChildrenContent (the rest).
  include_examples = [
    [Coridoc::CoreModel::Block, true],
    [Coridoc::CoreModel::ParagraphBlock, true],   # via Block
    [Coridoc::CoreModel::AnnotationBlock, true],  # via Block
    [Coridoc::CoreModel::InlineElement, true],
    [Coridoc::CoreModel::BoldElement, true],      # via InlineElement
    [Coridoc::CoreModel::TableCell, true],
    [Coridoc::CoreModel::ListItem, true],
    [Coridoc::CoreModel::StructuralElement, true],
    [Coridoc::CoreModel::DocumentElement, true],  # via StructuralElement
    [Coridoc::CoreModel::SectionElement, true]    # via StructuralElement
  ].freeze

  # Classes that should NOT satisfy HasChildren — they carry their own
  # named collection (e.g. Table#rows) or are leaf nodes with no
  # children.
  exclude_examples = [
    [Coridoc::CoreModel::TextContent, false],
    [Coridoc::CoreModel::Table, false], # has :rows, not :children
    [Coridoc::CoreModel::Image, false],
    [Coridoc::CoreModel::Metadata, false],
    [Coridoc::CoreModel::ElementAttribute, false]
  ].freeze

  include_examples.each do |klass, expected|
    it "#{klass} includes HasChildren (#{expected})" do
      instance = begin
        klass.new
      rescue StandardError
        klass.new(children: [])
      end
      expect(instance.is_a?(Coridoc::CoreModel::HasChildren)).to eq(expected)
      expect(instance.has_children?).to eq(expected)
    end
  end

  exclude_examples.each do |klass, _expected|
    it "#{klass} does NOT satisfy HasChildren" do
      instance = klass.new
      expect(instance.is_a?(Coridoc::CoreModel::HasChildren)).to be(false)
    end
  end
end
