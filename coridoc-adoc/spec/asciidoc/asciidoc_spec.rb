# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc do
  describe '.parse' do
    it 'parses simple AsciiDoc text' do
      text = "= Document Title\n\n== Section 1\n\nParagraph content."

      expect { described_class.parse(text) }.not_to raise_error
    end
  end

  describe 'format registration' do
    it 'registers the :asciidoc format with Coridoc' do
      expect(Coridoc.registered_formats).to include(:asciidoc)
    end

    it 'returns the AsciiDoc module from the registry' do
      expect(Coridoc.get_format(:asciidoc)).to eq(described_class)
    end
  end

  describe 'VERSION' do
    it 'has a version number' do
      expect(Coridoc::AsciiDoc::VERSION).not_to be_nil
      expect(Coridoc::AsciiDoc::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
