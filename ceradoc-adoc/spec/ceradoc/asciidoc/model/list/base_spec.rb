# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::AsciiDoc::Model::List::Base do
  describe 'inheritance hierarchy' do
    it 'Core inherits universal attrs from List::Base' do
      expect(described_class).to be > Ceradoc::AsciiDoc::Model::List::Core
    end

    it 'Definition inherits universal attrs from List::Base' do
      expect(described_class).to be > Ceradoc::AsciiDoc::Model::List::Definition
    end

    it 'Ordered inherits attrs transitively through Core/Nestable' do
      expect(described_class).to be > Ceradoc::AsciiDoc::Model::List::Ordered
    end

    it 'Unordered inherits attrs transitively through Core/Nestable' do
      expect(described_class).to be > Ceradoc::AsciiDoc::Model::List::Unordered
    end

    it 'List::Item is NOT under List::Base (items are not containers)' do
      expect(described_class).not_to be > Ceradoc::AsciiDoc::Model::List::Item
    end

    it 'DefinitionItem is NOT under List::Base' do
      expect(described_class).not_to be > Ceradoc::AsciiDoc::Model::List::DefinitionItem
    end
  end

  describe 'shared attrs attribute' do
    it 'Definition has attrs (regression for NoMethodError)' do
      dlist = Ceradoc::AsciiDoc::Model::List::Definition.new
      expect(dlist.attrs).to be_a(Ceradoc::AsciiDoc::Model::AttributeList)
    end

    it 'Ordered has attrs inherited from List::Base via Core/Nestable' do
      list = Ceradoc::AsciiDoc::Model::List::Ordered.new
      expect(list.attrs).to be_a(Ceradoc::AsciiDoc::Model::AttributeList)
    end

    it 'Definition is block-level' do
      expect(Ceradoc::AsciiDoc::Model::List::Definition.new.block_level?).to be(true)
    end

    it 'Core is block-level' do
      expect(Ceradoc::AsciiDoc::Model::List::Core.new.block_level?).to be(true)
    end
  end
end
