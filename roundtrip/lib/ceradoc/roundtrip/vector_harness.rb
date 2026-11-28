# frozen_string_literal: true

module Ceradoc
  module Roundtrip
    # Runs one sealed parity vector against one parse lane
    # (docs/_references/parity-vectors.adoc).
    #
    # Two properties, both against the SEALED bytes — never against a
    # regeneration, and never through hand-rolled data shaping:
    #
    #   byte_equality       lane.parse(vector.input) serializes to the
    #                       exact sealed bytes, per serialization format.
    #                       This is the cross-runtime parity property:
    #                       a runtime that reproduces the bytes has
    #                       produced an equivalent model tree.
    #
    #   structural_equality lane.load(sealed bytes) reduces to the same
    #                       Projection as lane.parse(vector.input): the
    #                       generated loader reconstructs the tree. Only
    #                       checked for lanes that supply loaders; the
    #                       first difference is reported by path.
    #
    # The Ruby lane comes from Vector::Capabilities; other runtimes
    # (#390) plug in a Lane with the same shape.
    module VectorHarness
      # One lane's machinery. +parse+ takes the input text and returns
      # the layer's model; +serializers+ and +loaders+ map a sealed
      # serialization format (:json, :yaml, ...) to a callable. A lane
      # that cannot load (e.g. a remote runtime reached only for its
      # serialized bytes) omits +loaders+; the structural property is
      # then not checked.
      Lane = Struct.new(:name, :parse, :serializers, :loaders, keyword_init: true)

      # One property outcome for one (vector, sealed format).
      # +detail+ is nil on success; on byte failure the first differing
      # line, on structural failure the Projection path and values.
      Result = Struct.new(:vector, :format, :property, :detail, keyword_init: true) do
        def ok? = detail.nil?

        def to_s = "#{vector.id}[#{format}] #{property}: #{detail}"
      end

      module_function

      # @param vector [Vector]
      # @param lane [Lane, nil] defaults to the Ruby lane for the
      #   vector's layer and format
      # @return [Array<Result>] one result per sealed format per property
      def call(vector, lane: nil)
        lane ||= Vector::Capabilities.ruby_lane(vector.layer, vector.format)
        model = lane.parse.call(vector.input)
        vector.sealed.flat_map do |fmt, sealed_bytes|
          results = [byte_result(vector, fmt, lane, model, sealed_bytes)]
          results << structural_result(vector, fmt, lane, model, sealed_bytes) if lane.loaders
          results
        end
      rescue StandardError => e
        [Result.new(vector: vector, format: nil, property: :lane_error,
                    detail: "#{e.class}: #{e.message.lines.first&.chomp}")]
      end

      def byte_result(vector, fmt, lane, model, sealed_bytes)
        actual = lane.serializers.fetch(fmt).call(model)
        detail = nil
        if actual != sealed_bytes
          line = Snippet.first_difference(actual, sealed_bytes)
          detail = "serialized bytes differ from sealed (first difference line #{line})"
        end
        Result.new(vector: vector, format: fmt, property: :byte_equality, detail: detail)
      rescue StandardError => e
        Result.new(vector: vector, format: fmt, property: :byte_equality,
                   detail: "serialization raised #{e.class}: #{e.message.lines.first&.chomp}")
      end

      def structural_result(vector, fmt, lane, model, sealed_bytes)
        reloaded = lane.loaders.fetch(fmt).call(sealed_bytes)
        path, left, right = Projection.first_difference(Projection.of(model), Projection.of(reloaded))
        detail = path && "loaded model differs at #{path} (first: #{short(left)}, again: #{short(right)})"
        Result.new(vector: vector, format: fmt, property: :structural_equality, detail: detail)
      rescue StandardError => e
        Result.new(vector: vector, format: fmt, property: :structural_equality,
                   detail: "loading sealed bytes raised #{e.class}: #{e.message.lines.first&.chomp}")
      end

      def short(value)
        text = value.inspect
        text.length > 120 ? "#{text[0, 120]}…" : text
      end
    end
  end
end
