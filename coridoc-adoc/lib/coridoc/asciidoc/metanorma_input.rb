# frozen_string_literal: true

require 'coridoc/asciidoc'

module Coridoc
  module AsciiDoc
    # Distinguishes authored section anchors from generic frontend-generated IDs.
    # The semantic builder assigns the latter consistently across source formats.
    module MetanormaInput
      module_function

      def transform(document)
        core = Transform::ToCoreModel.transform(document)
        sections(document, core)
        core
      end

      def sections(source, core)
        source_sections = Array(source.sections)
        core_sections = Array(core.children).grep(CoreModel::SectionElement)
        raise Coridoc::Metanorma::UnsupportedNode, 'AsciiDoc section shape changed during CoreModel conversion' unless source_sections.size == core_sections.size

        source_sections.zip(core_sections).each do |original, converted|
          converted.id = nil if original.id.nil?
          sections(original, converted)
        end
      end
      private_class_method :sections
    end
  end
end
