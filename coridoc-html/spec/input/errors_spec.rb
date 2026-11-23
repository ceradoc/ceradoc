# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coridoc::Html::Errors do
  describe 'Error' do
    it 'inherits from Coridoc::Error' do
      expect(described_class::Error).to be < Coridoc::Error
    end
  end

  describe 'UnknownTagError' do
    it 'inherits from Errors::Error' do
      expect(described_class::UnknownTagError).to be < described_class::Error
    end

    it 'can be raised with a message' do
      expect { raise described_class::UnknownTagError, 'unknown tag: foo' }
        .to raise_error(described_class::UnknownTagError, 'unknown tag: foo')
    end
  end

  describe 'InvalidConfigurationError' do
    it 'inherits from Errors::Error' do
      expect(described_class::InvalidConfigurationError).to be < described_class::Error
    end
  end
end
