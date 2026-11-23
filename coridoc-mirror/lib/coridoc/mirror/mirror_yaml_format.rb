# frozen_string_literal: true

require 'yaml'

module Coridoc
  module Mirror
    # Format module for mirror YAML output.
    #
    # Registers with Coridoc so the CLI can discover it:
    #   Coridoc.convert(text, from: :asciidoc, to: :mirror_yaml)
    #   coridoc convert doc.adoc -t mirror_yaml
    module MirrorYamlFormat
      class << self
        # Output-only format — parsing from mirror YAML is not supported via
        # the format registry. Use Mirror::Node.from_hash directly.
        def parse_to_core(_input, _options = {})
          raise Coridoc::UnsupportedFormatError,
                'Parsing from mirror YAML is not supported via the format registry. ' \
                'Use Coridoc::Mirror::Node.from_hash(YAML.safe_load(input)) directly.'
        end

        # Accept CoreModel, serialize to Mirror YAML.
        def serialize(document, _options = {})
          node = Coridoc::Mirror.transform(document)
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

Coridoc.register_format(:mirror_yaml, Coridoc::Mirror::MirrorYamlFormat,
                        extensions: %w[.mirror.yaml .mirror.yml])
