# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Serialization with unresolved includes' do
  let(:doc) do
    Coridoc::CoreModel::DocumentElement.new(
      id: 'd', title: 'D',
      children: [Coridoc::CoreModel::Include.new(target: 'shared/common.adoc')]
    )
  end

  it 'raises UnresolvedIncludesError instead of silently dropping content' do
    expect { Coridoc.serialize(doc, to: :html) }
      .to raise_error(Coridoc::UnresolvedIncludesError, %r{shared/common\.adoc})
  end

  it 'can be bypassed explicitly with allow_unresolved_includes: true' do
    expect { Coridoc.serialize(doc, to: :html, allow_unresolved_includes: true) }
      .not_to raise_error
  end
end
