# frozen_string_literal: true

module Coridoc
  module Metanorma
    class UnsupportedNode < ArgumentError; end

    # Constructs the SDK semantic graph directly from the shared CoreModel.
    # There is deliberately no intermediate XML representation.
    class Builder
      C = ::Metanorma::Document::Components
      S = ::Metanorma::Standoc::Document::Sections
      CORE = Coridoc::CoreModel
      INLINE = {
        'bold' => ['strong', C::Inline::StrongRawElement],
        'italic' => ['em', C::Inline::EmRawElement],
        'monospace' => ['tt', C::Inline::TtElement],
        'underline' => ['underline', C::TextElements::UnderlineElement],
        'strikethrough' => ['strike', C::TextElements::StrikeElement],
        'subscript' => ['sub', C::Inline::SubElement],
        'superscript' => ['sup', C::Inline::SupElement],
        'link' => ['link', C::Inline::LinkElement],
        'xref' => ['xref', C::Inline::XrefElement]
      }.freeze

      def self.build(document, root_class: ::Metanorma::Standoc::Document::Root)
        new(root_class).build(document)
      end

      def self.parse(source, format: :asciidoc, **options)
        frontend = case format.to_sym
                   when :asciidoc, :adoc
                     require 'coridoc/asciidoc'
                     Coridoc::AsciiDoc
                   when :markdown
                     require 'coridoc/markdown'
                     Coridoc::Markdown
                   else
                     raise ArgumentError, "Unsupported source format: #{format}"
                   end
        parsed = frontend.parse(source)
        core = if format.to_sym == :markdown
                 require 'coridoc/markdown/metanorma_input'
                 Coridoc::Markdown::MetanormaInput.transform(parsed)
               else
                 require 'coridoc/asciidoc/metanorma_input'
                 Coridoc::AsciiDoc::MetanormaInput.transform(parsed)
               end
        if parsed.frontmatter && !parsed.frontmatter.strip.empty?
          frontmatter = Array(core.children).grep(CORE::FrontmatterBlock).first
          if !frontmatter || (Array(frontmatter.entries).empty? && frontmatter.schema.nil?)
            raise UnsupportedNode, 'Empty or malformed source frontmatter at document/frontmatter'
          end
        end
        if format.to_sym == :markdown
          children = Array(core.children)
          title_index = children.index { |node| !node.is_a?(CORE::FrontmatterBlock) }
          first = title_index && children[title_index]
          if first.is_a?(CORE::SectionElement) && first.level == 1 && first.title == core.title
            core.id ||= first.id
            core.children = children.each_with_index.filter_map { |node, i| node unless i == title_index }
          end
        end
        build(core, **options)
      end

      def initialize(root_class)
        @root_class = root_class
      end

      def build(document)
        @ids = {}
        @sequence = Hash.new(0)
        @generated = {}
        raise ArgumentError, 'Expected CoreModel::DocumentElement' unless document.is_a?(CORE::DocumentElement)

        raise ArgumentError, 'Expected a native SDK Root class' unless @root_class.is_a?(Class) && @root_class <= ::Metanorma::Document::Root

        unsupported(document, 'document', 'string document body; use typed children') unless document.content.to_s.empty?
        reserve_ids(document, 'document')
        root = @root_class.new
        root.type = 'semantic' if root.respond_to?(:type=)
        root.bibdata = bibliography_data(document)
        root.sections = S::Sections.new
        @root = root
        body = Array(document.children)
        # Both formats can express headings as flat siblings. Normalize them
        # without changing the input graph, preserving explicitly nested sections.
        populate_sections(root.sections, body, 'document')
        root
      end

      private

      def reserve_ids(node, path)
        return unless node.is_a?(CORE::Base)
        unsupported(node, path, 'element attributes') unless Array(node.element_attributes).empty?
        unsupported(node, path, 'metadata entries') unless Array(node.metadata_entries).empty?
        if node.is_a?(CORE::HeaderElement) && node.document_title?
          unsupported(node, path, 'document title has body children') unless Array(node.children).empty?
          return
        end
        unless node.id.to_s.empty?
          raise ArgumentError, "Duplicate authored ID #{node.id.inspect} at #{path}" if @ids.key?(node.id)
          @ids[node.id] = path
        end
        if node.is_a?(CORE::BibliographyEntry) && node.anchor_name && node.anchor_name != node.id
          raise ArgumentError, "Duplicate authored ID #{node.anchor_name.inspect} at #{path}" if @ids.key?(node.anchor_name)
          @ids[node.anchor_name] = path
        end
        node.class.attributes.each_key do |name|
          next if name == :id
          Array(node.public_send(name)).each_with_index do |value, i|
            reserve_ids(value, "#{path}/#{name}/#{i}") if value.is_a?(CORE::Base)
          end
        end
      end

      def id(node, path)
        return node.id unless node.id.to_s.empty?
        return @generated[path] if @generated.key?(path)

        kind = node.class.name.split("::").last
        @sequence[kind] += 1
        candidate = "_coridoc_#{kind.downcase}_#{@sequence[kind]}"
        candidate += '_' while @ids.key?(candidate) && @ids[candidate] != path
        @ids[candidate] = path
        @generated[path] = candidate
      end

      def unsupported(node, path, detail = nil)
        raise UnsupportedNode, "#{node.class} at #{path}#{": #{detail}" if detail}"
      end

      # Resolve the SDK's XML vocabulary to its actual declared typed attribute.
      # Section/list/note classes use different Ruby names for the same XML tag.
      def append(parent, tag, value)
        mapping = parent.class.mappings_for(:xml)
        rule = tag == '#text' ? mapping.content_mapping : mapping.elements.find { |r| r.name.to_s == tag }
        raise UnsupportedNode, "#{parent.class} cannot contain #{tag}" unless rule

        name = rule.to
        definition = parent.class.attributes[name]
        if definition.collection?
          parent.public_send("#{name}=", Array(parent.public_send(name)) + [value])
        else
          raise UnsupportedNode, "Repeated singular #{tag} in #{parent.class}" if parent.public_send(name)
          parent.public_send("#{name}=", value)
        end
        order = tag == '#text' ? Lutaml::Xml::Element.new('Text', 'text', node_type: :text, text_content: value.to_s) : Lutaml::Xml::Element.new('Element', tag, node_type: :element)
        parent.element_order = Array(parent.element_order) + [order]
        value
      end

      def bibliography_data(document)
        title = document.title
        title ||= Array(document.children).find { |n| n.is_a?(CORE::HeaderElement) && n.document_title? }&.title
        bib = C::BibData::BibliographicItem.new(id: document.id)
        bib.title = [::Metanorma::Document::Relaton::TypedTitleString.new(content: [title])] if title
        values = Array(document.attributes&.entries).to_h { |entry| [entry.key, entry.value] }
        Array(document.children).grep(CORE::FrontmatterBlock).each do |frontmatter|
          unsupported(frontmatter, 'document/frontmatter', 'schema-bound frontmatter') if frontmatter.schema
          native = CORE::FrontmatterBlock::Codec.to_hash(frontmatter)
          values = values.merge(native.transform_keys(&:to_s))
        end
        unknown = values.keys - %w[docnumber docidentifier language title copyright-year copyright-holder]
        unsupported(document, 'document/attributes', "unsupported metadata: #{unknown.join(', ')}") unless unknown.empty?
        values.each do |key, value|
          unsupported(document, 'document/attributes', "non-scalar #{key}") unless value.is_a?(String) || value.is_a?(Numeric)
        end
        bib.title = [::Metanorma::Document::Relaton::TypedTitleString.new(content: [values['title'].to_s])] if values['title']
        if values['copyright-year'] || values['copyright-holder']
          unless values['copyright-year'] && values['copyright-holder']
            unsupported(document, 'document/attributes', 'copyright requires copyright-year and copyright-holder')
          end
          relaton = ::Metanorma::Document::Relaton
          organization = relaton::Organization.new(name: [relaton::LocalizedName.new(content: [values['copyright-holder'].to_s])])
          owner = relaton::CopyrightOwner.new(organization: organization)
          bib.copyright = [relaton::CopyrightAssociation.new(from: relaton::DateTime.new(content: values['copyright-year'].to_s), owner: [owner])]
        end
        bib.docnumber = values['docnumber'].to_s if values['docnumber']
        bib.language = [C::DataTypes::Iso639Code.new(value: values['language'])] if values['language']
        if values['docidentifier']
          bib.docidentifier = [::Metanorma::Document::Relaton::DocumentIdentifier.new(id: values['docidentifier'])]
        end
        bib
      end

      def populate_sections(container, nodes, path)
        stack = []
        loose = nil
        nodes.each_with_index do |node, index|
          at = "#{path}/#{index}"
          if node.is_a?(CORE::FrontmatterBlock)
            next
          elsif node.is_a?(CORE::Bibliography)
            bibliography(node, at)
          elsif node.is_a?(CORE::HeaderElement) && node.document_title?
            next
          elsif node.is_a?(CORE::SectionElement) || node.is_a?(CORE::HeaderElement)
            level = node.level || 1
            stack.pop while stack.any? && stack.last[0] >= level
            section_id = node.id || CORE::IdGenerator.generate_from_title(node.title, parent_id: stack.last&.last&.id)
            if node.id.nil? && section_id
              section_id += '_' while @ids.key?(section_id)
              @ids[section_id] = at
            end
            section = S::ClauseSection.new(id: section_id || id(node, at))
            if node.attributes && !Array(node.attributes.entries).empty?
              unsupported(node, at, 'section attributes')
            end
            section.title = C::Inline::TitleWithAnnotationElement.new(text: [node.title || node.content || ''])
            append(stack.empty? ? container : stack.last[1], 'clause', section)
            populate_sections(section, Array(node.children), "#{at}/children")
            stack << [level, section]
          elsif node.is_a?(CORE::PreambleElement)
            children = Array(node.children)
            if children.empty? && !node.content.to_s.empty?
              children = [CORE::ParagraphBlock.new(id: node.id, content: node.content)]
            end
            populate_sections(container, children, "#{at}/children")
          else
            target = stack.last&.last
            target ||= container if container.is_a?(S::ClauseSection)
            unless target
              loose ||= append(container, 'clause', S::ClauseSection.new(id: id(CORE::SectionElement.new, "#{path}/preamble")))
              target = loose
            end
            block(target, node, at)
          end
        end
      end

      def inline_content(target, node, path)
        children = node.respond_to?(:children) ? Array(node.children) : []
        if node.is_a?(CORE::InlineElement) && !Array(node.nested_elements).empty?
          unsupported(node, path, 'ambiguous children and nested_elements') unless children.empty?
          children = Array(node.nested_elements)
        end
        if children.empty?
          text = node.respond_to?(:text) ? node.text : node.content
          text ||= Array(node.lines).join("\n") if node.respond_to?(:lines) && !Array(node.lines).empty?
          append(target, '#text', text.to_s) unless text.nil?
        else
          children.each_with_index { |child, i| inline(target, child, "#{path}/#{i}") }
        end
      end

      def inline(parent, node, path)
        case node
        when CORE::Image
          unsupported(node, path, 'linked or captioned inline image') if node.link || node.caption
          append(parent, 'image', C::IdElements::Image.new(source: node.src, alt: node.alt, width: node.width, height: node.height))
        when CORE::TextContent
          append(parent, '#text', node.text.to_s)
        when CORE::InlineElement
          format = node.resolve_format_type
          if format == 'text'
            inline_content(parent, node, path)
          elsif format == 'footnote'
            fn = C::Inline::FnElement.new(id: id(node, path), reference: id(node, path))
            append(fn, 'p', paragraph(node, "#{path}/p", authored: false))
            append(parent, 'fn', fn)
          elsif %w[hard_line_break line_break].include?(format)
            append(parent, 'br', C::Inline::BrElement.new)
          elsif format == 'stem'
            unsupported(node, path, "math type #{node.stem_type}") unless [nil, 'stem', 'asciimath', 'AsciiMath', 'latexmath', 'latex', 'LaTeX'].include?(node.stem_type)
            stem = C::Inline::StemInlineElement.new(stem_type: node.stem_type || 'AsciiMath')
            if node.stem_type.to_s.downcase.include?('latex')
              stem.latexmath = [C::TextElements::LatexmathElement.new(value: node.content)]
            else
              stem.asciimath = [C::Inline::AsciimathElement.new(text: node.content)]
            end
            append(parent, 'stem', stem)
          elsif (mapping = INLINE[format])
            tag, klass = mapping
            element = klass.new
            element.id = node.id if node.id && element.respond_to?(:id=)
            unsupported(node, path, 'inline ID cannot be represented') if node.id && !element.respond_to?(:id=)
            element.target = node.target if %w[link xref].include?(format)
            inline_content(element, node, path)
            append(parent, tag, element)
          else
            unsupported(node, path, "inline format #{format.inspect}")
          end
        else
          unsupported(node, path, 'expected inline content')
        end
      end

      def paragraph(node, path, authored: true)
        p = C::Paragraphs::ParagraphBlock.new(id: authored ? id(node, path) : id(CORE::ParagraphBlock.new, path))
        inline_content(p, node, path)
        p
      end

      def block(parent, node, path)
        case node
        when CORE::StemBlock
          stem = C::TextElements::StemElement.new(stem_type: node.language)
          text = node.content || Array(node.lines).join("\n")
          if node.language.to_s.downcase.include?('latex')
            stem.latexmath = C::TextElements::LatexmathElement.new(value: text)
          elsif node.language.to_s.downcase == 'asciimath'
            stem.asciimath = C::TextElements::Asciiml.new(value: text)
          else
            unsupported(node, path, "math language #{node.language}")
          end
          append(parent, 'formula', C::AncillaryBlocks::FormulaBlock.new(id: id(node, path), stem: stem))
        when CORE::QuoteBlock, CORE::ExampleBlock
          tag, klass = node.is_a?(CORE::QuoteBlock) ? ['quote', C::MultiParagraph::QuoteBlock] : ['example', C::AncillaryBlocks::ExampleBlock]
          result = klass.new(id: id(node, path))
          result.name = [C::Inline::NameWithIdElement.new(text: node.title)] if node.title && node.is_a?(CORE::ExampleBlock)
          result.author = C::MultiParagraph::QuoteAuthorElement.new(text: node.attribution) if node.is_a?(CORE::QuoteBlock) && node.attribution
          children = Array(node.children)
          if children.empty? || children.all? { |c| c.is_a?(CORE::TextContent) || c.is_a?(CORE::InlineElement) }
            append(result, 'p', paragraph(node, "#{path}/p", authored: false))
          else
            children.each_with_index { |c, i| block(result, c, "#{path}/#{i}") }
          end
          append(parent, tag, result)
        when CORE::ParagraphBlock
          unsupported(node, path, 'paragraph caption') if node.title
          append(parent, 'p', paragraph(node, path))
        when CORE::DefinitionList
          list = C::Lists::DefinitionList.new(id: id(node, path))
          Array(node.items).each_with_index do |item, i|
            terms = Array(item.terms)
            terms = [item.term] if terms.empty?
            terms.each_with_index do |term, j|
              dt = C::Lists::DtElement.new(content: [term], id: j.zero? ? item.id : nil)
              append(list, 'dt', dt)
            end
            dd = C::Lists::DdElement.new
            Array(item.definitions).each_with_index do |text, j|
              append(dd, 'p', paragraph(CORE::ParagraphBlock.new(content: text), "#{path}/#{i}/#{j}"))
            end
            block(dd, item.nested, "#{path}/#{i}/nested") if item.nested
            Array(item.attached_children).each_with_index { |child, j| block(dd, child, "#{path}/#{i}/attached/#{j}") }
            append(list, 'dd', dd)
          end
          append(parent, 'dl', list)
        when CORE::ListBlock
          ordered = node.marker_type == 'ordered'
          unsupported(node, path, "list type #{node.marker_type}") unless %w[ordered unordered].include?(node.marker_type)
          list = (ordered ? C::Lists::OrderedList : C::Lists::UnorderedList).new(id: id(node, path))
          list.start = node.start.to_s if ordered && node.start
          Array(node.items).each_with_index do |item, i|
            at = "#{path}/items/#{i}"
            li = C::Lists::ListItem.new(id: id(item, at))
            append(li, 'p', paragraph(item, "#{at}/p", authored: false))
            block(li, item.nested_list, "#{at}/nested") if item.nested_list
            append(list, 'li', li)
          end
          append(parent, ordered ? 'ol' : 'ul', list)
        when CORE::Table
          append(parent, 'table', table(node, path))
        when CORE::Image
          unsupported(node, path, 'linked, floating or styled image') if node.link || node.float || node.role
          image = C::IdElements::Image.new(source: node.src, alt: node.alt, width: node.width, height: node.height)
          figure = C::AncillaryBlocks::FigureBlock.new(id: id(node, path), image: image)
          figure.name = C::Inline::NameWithIdElement.new(text: node.caption || node.title) if node.caption || node.title
          append(parent, 'figure', figure)
        when CORE::SourceBlock, CORE::ListingBlock
          unsupported(node, path, 'source callouts') unless Array(node.callouts).empty?
          text = node.content || Array(node.lines).join("\n")
          code = C::AncillaryBlocks::SourcecodeBlock.new(id: id(node, path), lang: node.language, content: text)
          code.name = C::Inline::NameWithIdElement.new(text: node.title) if node.title
          append(parent, 'sourcecode', code)
        when CORE::AnnotationBlock
          unsupported(node, path, "annotation #{node.annotation_type}") unless node.annotation_type.to_s.downcase == 'note'
          note = C::Blocks::NoteBlock.new(id: id(node, path))
          note.name = [C::Inline::NameWithIdElement.new(text: node.title)] if node.title
          append(note, 'p', paragraph(node, "#{path}/p", authored: false))
          append(parent, 'note', note)
        when CORE::Block
          if node.resolve_semantic_type == :paragraph
            append(parent, 'p', paragraph(node, path))
          else
            unsupported(node, path, "block type #{node.resolve_semantic_type}")
          end
        else
          unsupported(node, path)
        end
      end

      def bibliography(node, path)
        section = S::StandardReferencesSection.new(id: id(node, path), normative: false)
        section.title = C::Inline::TitleWithAnnotationElement.new(text: [node.title]) if node.title
        section.references = Array(node.entries).each_with_index.map do |entry, i|
          item = C::BibData::BibliographicItem.new(id: entry.anchor_name || id(entry, "#{path}/#{i}"))
          item.docidentifier = [::Metanorma::Document::Relaton::DocumentIdentifier.new(id: entry.document_id)] if entry.document_id
          item.formatted_ref = C::DataTypes::FormattedString.new(value: [entry.ref_text]) if entry.ref_text
          unsupported(entry, path, 'bibliographic URL') if entry.url
          item
        end
        @root.bibliography ||= S::BibliographySection.new
        append(@root.bibliography, 'references', section)
      end

      def table(node, path)
        result = C::Tables::TableBlock.new(id: id(node, path), width: node.width)
        result.name = C::Inline::NameWithIdElement.new(text: node.title) if node.title
        unsupported(node, path, 'table grid') if node.grid
        unless Array(node.cols).empty?
          result.colgroup = C::Tables::ColGroupElement.new(col: node.cols.map { |width| C::Tables::ColElement.new(width: width) })
        end
        body = C::Tables::TableBodySection.new
        Array(node.rows).each_with_index do |row, i|
          tr = C::Tables::TextTableRow.new(id: row.id)
          Array(row.cells).each_with_index do |cell, j|
            unsupported(cell, "#{path}/#{i}/#{j}", 'table cell style') if cell.style && !%w[default d].include?(cell.style)
            klass = cell.header || row.header ? C::Tables::HeaderTableCell : C::Tables::TextTableCell
            td = klass.new(id: cell.id, colspan: cell.colspan, rowspan: cell.rowspan, align: cell.alignment, valign: cell.vertical_alignment)
            inline_content(td, cell, "#{path}/#{i}/#{j}")
            append(tr, klass == C::Tables::HeaderTableCell ? 'th' : 'td', td)
          end
          append(body, 'tr', tr)
        end
        result.tbody = body
        result
      end
    end
  end
end
