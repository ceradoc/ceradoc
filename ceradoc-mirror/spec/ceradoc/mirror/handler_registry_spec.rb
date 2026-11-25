# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ceradoc::Mirror::HandlerRegistry do
  describe '#register and #entry_for' do
    it 'finds a registered handler by exact class' do
      registry = described_class.new
      handler = ->(el, _ctx) { el }
      registry.register(Ceradoc::CoreModel::ParagraphBlock, handler)

      entry = registry.entry_for(Ceradoc::CoreModel::ParagraphBlock.new)
      expect(entry.handler).to eq(handler)
    end

    it 'finds a handler via ancestor walk' do
      registry = described_class.new
      handler = ->(el, _ctx) { el }
      registry.register(Ceradoc::CoreModel::Block, handler)

      # SourceBlock inherits from Block
      entry = registry.entry_for(Ceradoc::CoreModel::SourceBlock.new)
      expect(entry.handler).to eq(handler)
    end

    it 'prefers exact match over ancestor' do
      registry = described_class.new
      base_handler = ->(_el, _ctx) { :base }
      specific_handler = ->(_el, _ctx) { :specific }
      registry.register(Ceradoc::CoreModel::Block, base_handler)
      registry.register(Ceradoc::CoreModel::SourceBlock, specific_handler)

      entry = registry.entry_for(Ceradoc::CoreModel::SourceBlock.new)
      expect(entry.handler).to eq(specific_handler)
    end

    it 'returns nil for unregistered class' do
      registry = described_class.new
      entry = registry.entry_for(Ceradoc::CoreModel::ParagraphBlock.new)
      expect(entry).to be_nil
    end
  end

  describe '#registered?' do
    it 'returns true for registered class' do
      registry = described_class.new
      registry.register(Ceradoc::CoreModel::Block, ->(el, _ctx) { el })
      expect(registry.registered?(Ceradoc::CoreModel::Block)).to be true
    end

    it 'returns false for unregistered class' do
      registry = described_class.new
      expect(registry.registered?(Ceradoc::CoreModel::Block)).to be false
    end
  end

  describe '#handle' do
    it 'dispatches to handler and returns result with concat flag' do
      registry = described_class.new
      handler = Module.new do
        # rubocop:disable Lint/UnusedMethodArgument
        def self.call(element, context:)
          "handled: #{element.class}"
        end
        # rubocop:enable Lint/UnusedMethodArgument
      end
      registry.register(Ceradoc::CoreModel::ParagraphBlock, handler)

      element = Ceradoc::CoreModel::ParagraphBlock.new
      result = registry.handle(element, context: nil)
      expect(result).to eq(['handled: Ceradoc::CoreModel::ParagraphBlock', false])
    end

    it 'dispatches to Proc handler' do
      registry = described_class.new
      handler = ->(element, _context) { "proc: #{element.class}" }
      registry.register(Ceradoc::CoreModel::Block, handler)

      element = Ceradoc::CoreModel::Block.new
      result = registry.handle(element, context: nil)
      expect(result).to eq(['proc: Ceradoc::CoreModel::Block', false])
    end

    it 'dispatches to specific method name' do
      registry = described_class.new
      handler = Module.new do
        def self.convert(_element, *)
          'converted'
        end
      end
      registry.register(Ceradoc::CoreModel::Block, handler, method_name: :convert)

      element = Ceradoc::CoreModel::Block.new
      result = registry.handle(element, context: nil)
      expect(result).to eq(['converted', false])
    end

    it 'passes extra_kwargs to handler' do
      registry = described_class.new
      handler = Module.new do
        # rubocop:disable Lint/UnusedMethodArgument
        def self.call(_element, context:, extra_option: nil)
          "extra: #{extra_option}"
        end
        # rubocop:enable Lint/UnusedMethodArgument
      end
      registry.register(Ceradoc::CoreModel::Block, handler, extra_kwargs: { extra_option: 'yes' })

      element = Ceradoc::CoreModel::Block.new
      result = registry.handle(element, context: nil)
      expect(result).to eq(['extra: yes', false])
    end

    it 'returns nil for unregistered element' do
      registry = described_class.new
      element = Ceradoc::CoreModel::Block.new
      result = registry.handle(element, context: nil)
      expect(result).to be_nil
    end

    it 'supports concat flag' do
      registry = described_class.new
      handler = ->(_element, _context) { [1, 2, 3] }
      registry.register(Ceradoc::CoreModel::Block, handler, concat: true)

      element = Ceradoc::CoreModel::Block.new
      result = registry.handle(element, context: nil)
      expect(result).to eq([[1, 2, 3], true])
    end
  end
end
