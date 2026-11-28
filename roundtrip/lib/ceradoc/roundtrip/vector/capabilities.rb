# frozen_string_literal: true

module Ceradoc
  module Roundtrip
    class Vector
      # What the generated machinery can do for each layer today, and
      # the Ruby runtime's lane through it.
      #
      # Sealing uses ONLY lutaml-generated serialization
      # (to_json/to_yaml) and loading (from_json/from_yaml) — no
      # hand-rolled data shaping. Two lanes are currently unavailable
      # for both layers and are omitted from every vector:
      #
      # - xml: both layers' root models are type-only (no element
      #   declared), so lutaml raises TypeOnlyMappingError; the
      #   CoreModel XML lane is being fixed separately (#405).
      # - toml: requires a tomlib/toml-rb adapter that the bundle
      #   does not carry.
      module Capabilities
        LAYERS = {
          'hub' => {
            asciidoc: {
              parse: ->(text) { Ceradoc.parse(text, format: :asciidoc) },
              root: 'Ceradoc::CoreModel::DocumentElement'
            },
            markdown: {
              parse: ->(text) { Ceradoc.parse(text, format: :markdown) },
              root: 'Ceradoc::CoreModel::DocumentElement'
            }
          },
          'format-model' => {
            asciidoc: {
              parse: ->(text) { Ceradoc::AsciiDoc.parse(text) },
              root: 'Ceradoc::AsciiDoc::Model::Document'
            },
            markdown: {
              parse: ->(text) { Ceradoc::Markdown.parse(text) },
              root: 'Ceradoc::Markdown::Document'
            }
          }
        }.freeze

        SEALED_FORMATS = %i[json yaml].freeze

        module_function

        def layer?(name) = LAYERS.key?(name)

        # @return [Array<String>] layers whose parse lane supports +format+
        def layers_for(format)
          LAYERS.filter_map { |layer, formats| layer if formats.key?(format) }
        end

        def formats(layer) = LAYERS.fetch(layer).keys

        def root(layer, format)
          Object.const_get(LAYERS.fetch(layer).fetch(format).fetch(:root))
        end

        # The Ruby runtime's lane for one (layer, format): parse the
        # input with the layer's parser, serialize and load with the
        # lutaml-generated methods. Other runtimes (#390) supply their
        # own lane with the same shape.
        def ruby_lane(layer, format)
          spec = LAYERS.fetch(layer).fetch(format)
          root = root(layer, format)
          VectorHarness::Lane.new(
            name: "ruby/#{layer}/#{format}",
            parse: spec.fetch(:parse),
            serializers: SEALED_FORMATS.to_h { |fmt| [fmt, ->(model) { model.public_send("to_#{fmt}") }] },
            loaders: SEALED_FORMATS.to_h { |fmt| [fmt, ->(bytes) { root.public_send("from_#{fmt}", bytes) }] }
          )
        end
      end
    end
  end
end
