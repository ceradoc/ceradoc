# frozen_string_literal: true

require 'spec_helper'

# ceradoc/ceradoc#321: list items carry inline children through the same
# run conversion as paragraphs, so bold/italic inside a list item keeps
# its run formatting instead of collapsing to plain text.
RSpec.describe 'DOCX list item inline runs' do
  def list_item_runs(markdown)
    core = Ceradoc.parse(markdown, format: :markdown)
    result = Ceradoc::Docx::Transform::FromCoreModel.transform(core)
    result.body.paragraphs.select do |para|
      para.properties&.num_id
    end
  end

  it 'renders list items as numbered/bulleted paragraphs' do
    paras = list_item_runs("- plain item\n")
    expect(paras.size).to eq(1)
    expect(run_text(paras.first.runs.first)).to eq('plain item')
  end

  it 'keeps bold and italic run properties inside list items (#321)' do
    paras = list_item_runs("- **bold** and *italic* item\n")
    expect(paras.size).to eq(1)

    runs = paras.first.runs
    texts = runs.map { |r| run_text(r) }
    expect(texts).to include('bold', 'italic')

    bold_run = runs.find { |r| run_text(r) == 'bold' }
    italic_run = runs.find { |r| run_text(r) == 'italic' }
    expect(bold_run.properties&.bold).not_to be_nil
    expect(italic_run.properties&.italic).not_to be_nil
  end
end
