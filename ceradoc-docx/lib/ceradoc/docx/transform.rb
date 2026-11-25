# frozen_string_literal: true

module Ceradoc
  module Docx
    module Transform
      autoload :Rule, 'ceradoc/docx/transform/rule'
      autoload :RuleRegistry, 'ceradoc/docx/transform/rule_registry'
      autoload :Context, 'ceradoc/docx/transform/context'
      autoload :ToCoreModel, 'ceradoc/docx/transform/to_core_model'
      autoload :FromCoreModel, 'ceradoc/docx/transform/from_core_model'
      autoload :StyleResolver, 'ceradoc/docx/transform/style_resolver'
      autoload :NumberingResolver, 'ceradoc/docx/transform/numbering_resolver'
      autoload :NumberingAccess, 'ceradoc/docx/transform/numbering_access'
      autoload :OrderedContent, 'ceradoc/docx/transform/ordered_content'
      autoload :FrontmatterCoreProperties, 'ceradoc/docx/transform/frontmatter_core_properties'

      # Element transform rules
      module Rules
        autoload :TextRule, 'ceradoc/docx/transform/rules/text_rule'
        autoload :BreakRule, 'ceradoc/docx/transform/rules/break_rule'
        autoload :RunRule, 'ceradoc/docx/transform/rules/run_rule'
        autoload :HyperlinkRule, 'ceradoc/docx/transform/rules/hyperlink_rule'
        autoload :ImageRule, 'ceradoc/docx/transform/rules/image_rule'
        autoload :FootnoteRule, 'ceradoc/docx/transform/rules/footnote_rule'
        autoload :HeadingRule, 'ceradoc/docx/transform/rules/heading_rule'
        autoload :ListItemRule, 'ceradoc/docx/transform/rules/list_item_rule'
        autoload :ParagraphRule, 'ceradoc/docx/transform/rules/paragraph_rule'
        autoload :TableRule, 'ceradoc/docx/transform/rules/table_rule'
        autoload :MathRule, 'ceradoc/docx/transform/rules/math_rule'
        autoload :BookmarkRule, 'ceradoc/docx/transform/rules/bookmark_rule'
        autoload :StructuredDocumentTagRule,
                 'ceradoc/docx/transform/rules/structured_document_tag_rule'
        autoload :SimpleFieldRule,
                 'ceradoc/docx/transform/rules/simple_field_rule'
        autoload :ProofErrorRule,
                 'ceradoc/docx/transform/rules/proof_error_rule'
      end
    end
  end
end
