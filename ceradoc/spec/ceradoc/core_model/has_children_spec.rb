# frozen_string_literal: true

require 'spec_helper'

# Locks in the HasChildren predicate so downstream dispatch can rely on
# `is_a?(HasChildren)` instead of enumerating subclasses (OCP).
RSpec.describe Ceradoc::CoreModel::HasChildren do
  # Classes that carry a +children+ collection and should satisfy
  # HasChildren — either directly (StructuralElement) or transitively
  # via ChildrenContent (the rest).
  include_examples = [
    [Ceradoc::CoreModel::Block, true],
    [Ceradoc::CoreModel::ParagraphBlock, true],   # via Block
    [Ceradoc::CoreModel::AnnotationBlock, true],  # via Block
    [Ceradoc::CoreModel::InlineElement, true],
    [Ceradoc::CoreModel::BoldElement, true],      # via InlineElement
    [Ceradoc::CoreModel::TableCell, true],
    [Ceradoc::CoreModel::ListItem, true],
    [Ceradoc::CoreModel::StructuralElement, true],
    [Ceradoc::CoreModel::DocumentElement, true],  # via StructuralElement
    [Ceradoc::CoreModel::SectionElement, true]    # via StructuralElement
  ].freeze

  # Classes that should NOT satisfy HasChildren — they carry their own
  # named collection (e.g. Table#rows) or are leaf nodes with no
  # children.
  exclude_examples = [
    [Ceradoc::CoreModel::TextContent, false],
    [Ceradoc::CoreModel::Table, false], # has :rows, not :children
    [Ceradoc::CoreModel::Image, false],
    [Ceradoc::CoreModel::Metadata, false],
    [Ceradoc::CoreModel::ElementAttribute, false]
  ].freeze

  include_examples.each do |klass, expected|
    it "#{klass} includes HasChildren (#{expected})" do
      instance = begin
        klass.new
      rescue StandardError
        klass.new(children: [])
      end
      expect(instance.is_a?(Ceradoc::CoreModel::HasChildren)).to eq(expected)
      expect(instance.has_children?).to eq(expected)
    end
  end

  exclude_examples.each do |klass, _expected|
    it "#{klass} does NOT satisfy HasChildren" do
      instance = klass.new
      expect(instance.is_a?(Ceradoc::CoreModel::HasChildren)).to be(false)
    end
  end
end
