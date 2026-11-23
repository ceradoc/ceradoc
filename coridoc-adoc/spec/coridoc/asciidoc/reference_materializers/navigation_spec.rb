# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::AsciiDoc::ReferenceMaterializers::Navigation do
  let(:materializer) { described_class.new }
  let(:address) { Coridoc::Reference::Address.parse('sec-3') }

  let(:target) do
    Coridoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: [])
  end

  it 'renders a first-class CrossReferenceElement (never a raw macro string)' do
    edge = Coridoc::Reference::Edge.build(kind: :navigation, address: address, label: 'Section 3')
    result = Coridoc::Reference::Result::Resolved.build(edge: edge, address: address, target: target)
    inline = materializer.materialize(edge: edge, result: result, node: nil, presentation: nil, pages: [])
    expect(inline).to be_a(Coridoc::CoreModel::CrossReferenceElement)
    expect(inline.target).to eq('sec-3')
    expect(inline.content).to eq('Section 3')
  end

  it 'fills the visible text from the resolved target title when no label was authored' do
    edge = Coridoc::Reference::Edge.build(kind: :navigation, address: address)
    result = Coridoc::Reference::Result::Resolved.build(edge: edge, address: address, target: target)
    inline = materializer.materialize(edge: edge, result: result, node: nil, presentation: nil, pages: [])
    expect(inline.content).to eq('Sec 3')
  end

  it 'keeps the fragment in the xref target' do
    frag_address = Coridoc::Reference::Address.parse('ELF-5005-1#sec-3', hint: :path)
    edge = Coridoc::Reference::Edge.build(kind: :navigation, address: frag_address, label: 'x')
    result = Coridoc::Reference::Result::Missing.build(edge: edge, address: frag_address)
    inline = materializer.materialize(edge: edge, result: result, node: nil, presentation: nil, pages: [])
    expect(inline.target).to eq('ELF-5005-1#sec-3')
  end

  describe 'end-to-end: parse, resolve, serialize' do
    let(:adoc) do
      "= Doc\n\n[[sec-a]]\n== Section A\n\nSee <<sec-b>>.\n\n[[sec-b]]\n== Section B\n"
    end

    it 'round-trips xrefs as xrefs (no link-macro degradation)' do
      doc = Coridoc.parse(adoc, format: :asciidoc)
      resolved = Coridoc.resolve_references(
        doc,
        catalog: Coridoc::Reference::Catalog::Local.from_doc(doc),
        presentation: Coridoc::Reference::Presentation::SingleDocument.new,
        format: :asciidoc,
        materialize: true
      )
      output = Coridoc.serialize(resolved, to: :asciidoc)
      expect(output).to include('<<sec-b')
      expect(output).not_to include('link:')
    end
  end
end
