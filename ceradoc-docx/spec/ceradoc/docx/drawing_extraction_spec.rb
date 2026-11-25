# frozen_string_literal: true

require 'spec_helper'

# ceradoc/ceradoc#322: a DOCX paragraph carrying a w:drawing must produce
# a CoreModel Image node whose src carries the media reference, so
# downstream conversions keep the image instead of dropping it.
RSpec.describe 'DOCX drawing extraction' do
  let(:tmpdir) { Dir.mktmpdir }

  let(:minimal_png) do
    png = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xAEB`\x82".b
    path = File.join(tmpdir, 'fixture.png')
    File.binwrite(path, png)
    path
  end

  def image_nodes(docx_path)
    loaded = Uniword.load(docx_path)
    core = Ceradoc::Docx.parse_to_core(loaded)
    nodes = []
    walker = lambda do |node, depth|
      next if node.nil? || depth > 6

      nodes << node if node.is_a?(Ceradoc::CoreModel::Image)
      Array(node.children).each { |child| walker.call(child, depth + 1) } if node.respond_to?(:children)
    end
    walker.call(core, 0)
    nodes
  end

  it 'extracts an embedded image into a CoreModel Image node' do
    doc = Uniword::Builder::DocumentBuilder.new
    doc.heading('Image Test', level: 1)
    doc.image(minimal_png, alt_text: 'Test image')
    doc.paragraph('Text after image.')

    docx_path = File.join(tmpdir, 'image_extract.docx')
    doc.build.save(docx_path)

    images = image_nodes(docx_path)
    expect(images.size).to eq(1)

    image = images.first
    expect(image.src).not_to be_nil
    expect(image.src).not_to be_empty
    # uniword names the drawing after the media file (docPr name), not
    # the builder's alt_text — the alt rides the media stem here.
    expect(image.alt).to eq('fixture')
  end
end
