# frozen_string_literal: true

require 'yaml'

module Ceradoc
  module Mirror
    # Format module for mirror YAML output.
    #
    # Registers with Ceradoc so the CLI can discover it:
    #   Ceradoc.convert(text, from: :asciidoc, to: :mirror_yaml)
    #   ceradoc convert doc.adoc -t mirror_yaml
    module MirrorYamlFormat
      class << self
        # Output-only format — parsing from mirror YAML is not supported via
        # the format registry. Use Mirror::Node.from_hash directly.
        def parse_to_core(_input, _options = {})
          raise Ceradoc::UnsupportedFormatError,
                'Parsing from mirror YAML is not supported via the format registry. ' \
                'Use Ceradoc::Mirror::Node.from_hash(YAML.safe_load(input)) directly.'
        end

        # Accept CoreModel, serialize to Mirror YAML.
        def serialize(document, _options = {})
          node = Ceradoc::Mirror.transform(document)
          YAML.dump(node.to_hash)
        end

        def serialize?
          true
        end

        # Mirror YAML carries include edges as typed nodes — graph-mode
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

Ceradoc.register_format(:mirror_yaml, Ceradoc::Mirror::MirrorYamlFormat,
                        extensions: %w[.mirror.yaml .mirror.yml])
