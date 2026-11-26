# frozen_string_literal: true

module Ceradoc
  # Model-driven linting (#165).
  #
  # Rules live in the FORMAT gems and check the format-specific model
  # tree — never raw text, never a homogenized CoreModel. Each rule
  # declares its format and its check; the framework selects rules by
  # format and runs them against the parsed tree a SourceGraph node
  # exposes (parsing lazily, only files actually linted).
  #
  #   require "ceradoc/asciidoc"          # or any format gem you lint
  #   diagnostics = Ceradoc::Lint.run("doc.adoc")
  #   diagnostics.each { |d| puts d }
  #
  # Findings are Diagnostics (#377): identity = namespaced rule code,
  # severity/policy = data layers (Lint::Policy.resolve), channels are
  # generated serializers over the model.
  #
  # Format gems must be required (or +format:+ passed) — extension
  # detection only sees registered formats, like the rest of Ceradoc.
  module Lint
    autoload :Diagnostic, "#{__dir__}/lint/diagnostic"
    autoload :Diagnostics, "#{__dir__}/lint/diagnostics"
    autoload :MessageParam, "#{__dir__}/lint/message_param"
    autoload :PolicyEntry, "#{__dir__}/lint/policy"
    autoload :PolicyLayer, "#{__dir__}/lint/policy"
    autoload :Policy, "#{__dir__}/lint/policy"
    autoload :Channel, "#{__dir__}/lint/channel"
    autoload :Rule, "#{__dir__}/lint/rule"
    autoload :Template, "#{__dir__}/lint/template"
    autoload :Registry, "#{__dir__}/lint/registry"
    autoload :Runner, "#{__dir__}/lint/runner"

    class << self
      def registry
        @registry ||= Registry.new
      end

      # Lint files (or an existing SourceGraph) with the rules
      # registered for each file's format.
      #
      # @param sources [String, Array<String>, SourceGraph::Graph]
      # @param format [Symbol, nil] force a format instead of
      #   detecting from the extension
      # @param only [Array<Symbol>] restrict to these rule codes
      # @param except [Array<Symbol>] skip these rule codes
      # @return [Array<Diagnostic>]
      def run(sources, format: nil, only: nil, except: nil)
        Runner.new(format: format, only: only, except: except).run(sources)
      end
    end
  end
end
