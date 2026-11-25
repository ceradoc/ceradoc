# frozen_string_literal: true

require 'ceradoc/asciidoc'

module Ceradoc
  module AsciiDoc
    # Distinguishes authored section anchors from generic frontend-generated IDs.
    # The semantic builder assigns the latter consistently across source formats.
    module MetanormaInput
      module_function

      def transform(document)
        core = Transform::ToCoreModel.transform(document)
        sections(document, core)
        cross_references(document, core)
        core
      end

      def sections(source, core)
        source_sections = Array(source.sections)
        core_sections = Array(core.children).grep(CoreModel::SectionElement)
        raise Ceradoc::Metanorma::UnsupportedNode, 'AsciiDoc section shape changed during CoreModel conversion' unless source_sections.size == core_sections.size

        source_sections.zip(core_sections).each do |original, converted|
          converted.id = nil if original.id.nil?
          sections(original, converted)
        end
      end

      def cross_references(source, core)
        originals = collect_nodes(source, Model::Inline::CrossReference)
        converted = collect_nodes(core, CoreModel::CrossReferenceElement)
        raise Ceradoc::Metanorma::UnsupportedNode, 'AsciiDoc cross-reference shape changed during CoreModel conversion' unless originals.size == converted.size

        originals.zip(converted).each do |original, node|
          node.content = nil if Array(original.args).empty?
        end
      end

      def collect_nodes(node, klass, seen = {}.compare_by_identity)
        return [] if seen[node]

        seen[node] = true
        return node.flat_map { |child| collect_nodes(child, klass, seen) } if node.is_a?(Array)
        return [] unless node.is_a?(Lutaml::Model::Serializable)

        out = node.is_a?(klass) ? [node] : []
        node.class.attributes.each_key do |name|
          value = node.public_send(name)
          next unless value.is_a?(Array) || value.is_a?(Lutaml::Model::Serializable)

          out.concat(collect_nodes(value, klass, seen))
        end
        out
      end
      private_class_method :sections, :cross_references, :collect_nodes
    end
  end
end
