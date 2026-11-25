# frozen_string_literal: true

module Coridoc
  module Metanorma
    # ISO has its own Serializable root and bibliographic vocabulary. Construct
    # those types directly; it is not a Standoc root subclass or an XML cast.
    class IsoBuilder < Builder
      ISO = ::Metanorma::Iso::Document

      def build(document)
        root = super
        root.flavor = flavor_name if root.respond_to?(:flavor=)
        root
      end

      private

      def flavor_name
        @root_class.name.to_s[/\AMetanorma::(\w+)::Document::Root\z/, 1]&.downcase || 'iso'
      end

      def native_root_class?
        self.class.native_root?(@root_class)
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
