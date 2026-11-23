# frozen_string_literal: true

module Coridoc
  module Metanorma
    # ISO has its own Serializable root and bibliographic vocabulary. Construct
    # those types directly; it is not a Standoc root subclass or an XML cast.
    class IsoBuilder < Builder
      ISO = ::Metanorma::Iso::Document

      def build(document)
        root = super
        root.flavor = 'iso'
        root
      end

      private

      def native_root_class?
        @root_class.is_a?(Class) && @root_class <= ISO::Root
      end

      def sections_class
        ISO::Sections::IsoSections
      end

      def clause_class
        ISO::Sections::IsoClauseSection
      end

      def section_model(node, at, parent)
        section = super
        section.type = 'scope' if parent.nil? && node.title.to_s.strip.casecmp('Scope').zero?
        section
      end

      def metadata_keys
        super + %w[mn-document-class doctype]
      end

      def bibliography_data(document)
        title, values = document_metadata(document)
        unsupported(document, 'document/id', 'ISO bibdata cannot represent a document anchor') if document.id
        unsupported(document, 'document/attributes', 'mn-document-class does not match ISO root') if values['mn-document-class'] && values['mn-document-class'] != 'iso'
        metadata = ISO::Metadata
        bib = metadata::IsoBibliographicItem.new
        if title
          bib.titles = [metadata::TitleFull.new(_type: 'main', value: title,
                                                language: values['language'])]
        end
        bib.docnumber = values['docnumber'].to_s if values['docnumber']
        bib.doc_identifier = [metadata::DocIdentifier.new(value: values['docidentifier'])] if values['docidentifier']
        bib.language = [metadata::LanguageElement.new(value: values['language'], current: 'true')] if values['language']
        bib.copyright = copyright_data(document, values)
        if values['doctype']
          bib.ext = metadata::IsoBibDataExtensionType.new(
            doctype_element: [metadata::DoctypeElement.new(value: values['doctype'])]
          )
        end
        bib
      end
    end
  end
end
