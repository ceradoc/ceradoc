# frozen_string_literal: true

require 'digest'
require 'json'
require 'date'
require 'time'

module Ceradoc
  module SourceGraph
    # Stage-boundary content hash for a parsed model tree (#383).
    #
    # Change-proportional rebuilds key on this hash: when a file's
    # digest is unchanged from the previous build, every stage after
    # the parse stage can reuse its output. The hash must therefore be
    # deterministic across runs and processes — no object ids, no
    # hash-order dependence. It is derived by walking the model in a
    # FIXED canonical order (attribute declaration order, the same
    # walk the Roundtrip Projection uses) and hashing the JSON form of
    # the reduction.
    #
    # Positional bookkeeping attributes (+source_line+) are excluded,
    # like Projection does: where an element starts is not part of
    # document meaning, and a reflow that shifts every line must not
    # invalidate downstream stages.
    module ModelDigest
      IGNORED_ATTRIBUTES = %i[source_line].freeze

      module_function

      # @param model [Lutaml::Model::Serializable] a parsed model tree
      # @return [String] SHA256 hex digest of the canonical content
      def of(model)
        ::Digest::SHA256.hexdigest(JSON.generate(canonical(model)))
      end

      # Reduce a model tree to plain data in canonical order: nested
      # models become +{ '@type' => class, attribute => value }+ in
      # declaration order, nil and empty-array attributes are dropped,
      # scalars are normalized to JSON-stable primitives.
      def canonical(node)
        case node
        when Lutaml::Model::Serializable then model_canon(node)
        when Array then node.map { |child| canonical(child) }
        when Hash then hash_canon(node)
        else scalar_canon(node)
        end
      end

      def model_canon(node)
        canon = { '@type' => node.class.name }
        (node.class.attributes.keys - IGNORED_ATTRIBUTES).each do |name|
          value = canonical(node.public_send(name))
          canon[name.to_s] = value unless value.nil? || value == []
        end
        canon
      end

      # Key order inside a free-form hash is data-dependent; sorting
      # the canonicalized pairs makes the reduction order-independent.
      def hash_canon(node)
        canon = node.each_with_object({}) do |(key, value), pairs|
          pairs[key.to_s] = canonical(value)
        end
        canon.sort_by { |key, _value| key }.to_h
      end

      # Objects outside the primitive set would leak object ids
      # (default #to_s) or class-specific formats into the hash —
      # both forbidden in a cross-process digest. Raising surfaces the
      # gap instead of poisoning the digest (matches the serializers'
      # unknown-type policy).
      def scalar_canon(value)
        case value
        when String, Integer, Float, TrueClass, FalseClass, NilClass then value
        when Symbol then value.to_s
        when ::Date, ::DateTime, ::Time then value.iso8601
        else
          raise ArgumentError,
                "cannot canonically digest a #{value.class} value"
        end
      end
    end
  end
end
