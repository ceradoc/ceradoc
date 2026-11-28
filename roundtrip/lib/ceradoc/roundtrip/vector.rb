# frozen_string_literal: true

module Ceradoc
  module Roundtrip
    # One sealed parity vector (docs/_references/parity-vectors.adoc).
    #
    # A vector pins a single input text at a single layer to the exact
    # bytes the layer's generated serializations produced when the
    # vector was sealed: any runtime whose parse lane serializes to the
    # same bytes has produced an equivalent model tree for that layer.
    #
    # +layer+ is +hub+ (CoreModel) or +format-model+ (the grammar's
    # direct output model); +format+ is the source format (:asciidoc or
    # :markdown); +sealed+ maps a serialization format (:json, :yaml)
    # to the sealed bytes. +id+ is +<case-id>@<layer>+ where +<case-id>+
    # is the round-trip corpus id (+<format>:<relative>+).
    Vector = Struct.new(:id, :layer, :format, :input, :sealed) do
      def to_s = id

      # The round-trip corpus case this vector was sealed from.
      def case_id = id.split('@').first

      # Case path relative to its format, e.g. +edge/empty+.
      def case_relative = case_id.delete_prefix("#{format}:")

      # Vector files relative to the vectors directory.
      def input_path = File.join(format.to_s, layer, "#{case_relative}.input")

      def sealed_paths
        sealed.to_h { |fmt, _| [fmt.to_s, File.join(format.to_s, layer, "#{case_relative}.#{fmt}")] }
      end
    end

    # The immediate parent namespace of these classes is Vector itself,
    # so their autoload entries are registered on the Struct class.
    Vector.autoload :Capabilities, 'ceradoc/roundtrip/vector/capabilities'
    Vector.autoload :Gaps, 'ceradoc/roundtrip/vector/gaps'
    Vector.autoload :Adversarial, 'ceradoc/roundtrip/vector/adversarial'
    Vector.autoload :Store, 'ceradoc/roundtrip/vector/store'
  end
end
