# frozen_string_literal: true

require 'spec_helper'

# coridoc/coridoc#332: the constrained/unconstrained marker spelling the
# parser records must survive adoc -> CoreModel -> adoc; the flank walk
# stays only as the fallback for constraint-less sources.
RSpec.describe 'emphasis constraint round-trip' do
  def roundtrip(adoc)
    Coridoc.convert(adoc, from: :asciidoc, to: :asciidoc)
  end

  {
    'constrained bold with constrained italic' => "**__other__**\n",
    'unconstrained bold with unconstrained italic' => "*_other_*\n",
    'plain unconstrained bold' => "*bold text*\n",
    'word-attached constrained bold' => "foo**bar**baz\n"
  }.each do |name, source|
    it "preserves the marker spelling: #{name}" do
      # convert normalizes the trailing newline; the marker spelling and
      # constraint are what this contract pins.
      expect(roundtrip(source)).to eq(source.chomp)
    end
  end

  it 'records the constraint on CoreModel inline elements' do
    core = Coridoc.parse("**bold**text\n", format: :asciidoc)
    bold = nil
    walker = lambda do |node, depth|
      return if bold || node.nil?
      if node.is_a?(Coridoc::CoreModel::InlineElement)
        bold = node
      elsif node.respond_to?(:children) && depth < 5
        Array(node.children).each { |c| walker.call(c, depth + 1) }
      end
    end
    walker.call(core, 0)
    expect(bold.constraint).to eq('unconstrained')
  end
end
