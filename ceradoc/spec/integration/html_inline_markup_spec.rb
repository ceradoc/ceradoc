# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'HTML inline markup to AsciiDoc (#372)', type: :integration do
  # The HTML Markup converter parks an inline element's subtree under
  # `nested_elements`; the AsciiDoc writer walks it so styled content
  # is never dropped on the html→asciidoc path.
  def convert(html)
    Ceradoc.convert(html, from: :html, to: :asciidoc)
  end

  it 'converts the issue repro keeping both styled spans' do
    expect(convert('<p>hello <b>world</b> and <em>soft</em></p>'))
      .to include('*world*').and include('_soft_')
  end

  it 'converts plain b content' do
    expect(convert('<p><b>bold</b></p>')).to include('*bold*')
  end

  it 'converts strong content' do
    expect(convert('<p><strong>strong</strong></p>')).to include('*strong*')
  end

  it 'converts em content' do
    expect(convert('<p><em>soft</em></p>')).to include('_soft_')
  end

  it 'converts i content' do
    expect(convert('<p>plain <i>italic</i> text</p>'))
      .to include('plain _italic_ text')
  end

  it 'converts nested b>i with italic innermost' do
    expect(convert('<p><b><i>both</i></b></p>')).to include('*_both_*')
  end

  it 'converts nested i>b with italic innermost' do
    expect(convert('<p><i><b>both</b></i></p>')).to include('*_both_*')
  end

  it 'keeps bold text nested inside a link label' do
    html = '<p>see <a href="http://example.com"><b>link</b></a> now</p>'
    expect(convert(html)).to include('see http://example.com[link] now')
  end

  it 'keeps mixed text and markup inside one styled span' do
    expect(convert('<p><b>x<i>y</i>b</b></p>')).to include('*x')
      .and include('y')
      .and include('b*')
  end
end
