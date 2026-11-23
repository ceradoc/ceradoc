# frozen_string_literal: true

require 'json'

module Coridoc
  module Mirror
    # Format module for mirror JSON output.
    #
    # Registers with Coridoc so the CLI can discover it:
    #   Coridoc.convert(text, from: :asciidoc, to: :mirror_json)
    #   coridoc convert doc.adoc -t mirror_json
    module MirrorJsonFormat
      class << self
        # Output-only format — parsing from mirror JSON is not supported via
        # the format registry. Use Mirror::Node.from_hash directly.
        def parse_to_core(_input, _options = {})
          raise Coridoc::UnsupportedFormatError,
                'Parsing from mirror JSON is not supported via the format registry. ' \
                'Use Coridoc::Mirror::Node.from_hash(JSON.parse(input)) directly.'
        end

        # Accept CoreModel, serialize to Mirror JSON.
        def serialize(document, options = {})
          pretty = options[:pretty] != false
          node = Coridoc::Mirror.transform(document)
          pretty ? JSON.pretty_generate(node.to_hash) : JSON.generate(node.to_hash)
        end

        def serialize?
          true
        end

        # Mirror JSON carries include edges as typed nodes — graph-mode
        # documents round-trip losslessly.
        def preserves_unresolved_includes?
          true
        end

        def handles_model?(_model)
          false
        end
      end
    end
  end
end

Coridoc.register_format(:mirror_json, Coridoc::Mirror::MirrorJsonFormat,
                        extensions: %w[.mirror.json])
