# frozen_string_literal: true

require 'spec_helper'
require 'coridoc/asciidoc'
require 'coridoc-mirror'

RSpec.describe 'Code-block variants (source / literal / pass / stem)', :asciidoc do
  def first_node_type(adoc)
    json = JSON.parse(Coridoc.serialize(Coridoc.parse(adoc, format: :asciidoc), to: :mirror_json))
    [json.dig('content', 0, 'type'), json.dig('content', 0, 'attrs')]
  end

  it 'source blocks emit type=sourcecode' do
    adoc = "[source,ruby]\n----\nputs 'hi'\n----\n"
    type, attrs = first_node_type(adoc)
    expect(type).to eq('sourcecode')
    expect(attrs['language']).to eq('ruby')
  end

  it 'literal blocks emit type=literal (not sourcecode)' do
    adoc = "....\n  indented literal\n....\n"
    expect(first_node_type(adoc).first).to eq('literal')
  end

  it 'pass blocks emit type=pass (not sourcecode)' do
    adoc = "++++\n<p>raw html</p>\n++++\n"
    type, attrs = first_node_type(adoc)
    expect(type).to eq('pass')
    expect(attrs['passthrough']).to be(true)
  end

  it '[stem] emits type=stem with language=latex' do
    adoc = "[stem]\n++++\nx^2\n++++\n"
    type, attrs = first_node_type(adoc)
    expect(type).to eq('stem')
    expect(attrs['language']).to eq('latex')
  end

  it '[latexmath] emits type=stem with language=latex' do
    adoc = "[latexmath]\n++++\nx^2\n++++\n"
    type, attrs = first_node_type(adoc)
    expect(type).to eq('stem')
    expect(attrs['language']).to eq('latex')
  end

  it '[asciimath] emits type=stem with language=asciimath' do
    adoc = "[asciimath]\n++++\nx^2\n++++\n"
    type, attrs = first_node_type(adoc)
    expect(type).to eq('stem')
    expect(attrs['language']).to eq('asciimath')
  end

  it 'preserves block content verbatim' do
    adoc = "[stem]\n++++\nx^2 + y^2 = z^2\n++++\n"
    json = JSON.parse(Coridoc.serialize(Coridoc.parse(adoc, format: :asciidoc), to: :mirror_json))
    # text may be in attrs.text (partition mode) or in content[0].text
    text = json.dig('content', 0, 'attrs', 'text') ||
           json.dig('content', 0, 'content', 0, 'text')
    expect(text).to eq('x^2 + y^2 = z^2')
  end

  context 'round-trip (mirror → CoreModel)' do
    def round_trip(adoc)
      core = Coridoc.parse(adoc, format: :asciidoc)
      json = JSON.parse(Coridoc.serialize(core, to: :mirror_json))
      Coridoc::Mirror.from_hash(json).then do |node|
        Coridoc::Mirror::MirrorToCoreModel.new.call(node)
      end
    end

    it 'literal round-trips to CoreModel::LiteralBlock' do
      adoc = "....\ntext\n....\n"
      core = round_trip(adoc)
      first = core.children.first
      expect(first).to be_a(Coridoc::CoreModel::LiteralBlock)
    end

    it 'pass round-trips to CoreModel::PassBlock' do
      adoc = "++++\nraw\n++++\n"
      core = round_trip(adoc)
      first = core.children.first
      expect(first).to be_a(Coridoc::CoreModel::PassBlock)
    end

    it 'stem round-trips to CoreModel::StemBlock with language' do
      adoc = "[asciimath]\n++++\nx^2\n++++\n"
      core = round_trip(adoc)
      first = core.children.first
      expect(first).to be_a(Coridoc::CoreModel::StemBlock)
      expect(first.language).to eq('asciimath')
    end

    it 'source round-trips to CoreModel::SourceBlock' do
      adoc = "[source,ruby]\n----\nputs 'hi'\n----\n"
      core = round_trip(adoc)
      expect(core.children.first).to be_a(Coridoc::CoreModel::SourceBlock)
    end
  end
end
