# frozen_string_literal: true

module Coridoc
  module Docx
    module Transform
      autoload :Rule, 'coridoc/docx/transform/rule'
      autoload :RuleRegistry, 'coridoc/docx/transform/rule_registry'
      autoload :Context, 'coridoc/docx/transform/context'
      autoload :ToCoreModel, 'coridoc/docx/transform/to_core_model'
      autoload :FromCoreModel, 'coridoc/docx/transform/from_core_model'
      autoload :StyleResolver, 'coridoc/docx/transform/style_resolver'
      autoload :NumberingResolver, 'coridoc/docx/transform/numbering_resolver'
      autoload :NumberingAccess, 'coridoc/docx/transform/numbering_access'
      autoload :OrderedContent, 'coridoc/docx/transform/ordered_content'
      autoload :FrontmatterCoreProperties, 'coridoc/docx/transform/frontmatter_core_properties'

      # Element transform rules
      module Rules
        autoload :TextRule, 'coridoc/docx/transform/rules/text_rule'
        autoload :BreakRule, 'coridoc/docx/transform/rules/break_rule'
        autoload :RunRule, 'coridoc/docx/transform/rules/run_rule'
        autoload :HyperlinkRule, 'coridoc/docx/transform/rules/hyperlink_rule'
        autoload :ImageRule, 'coridoc/docx/transform/rules/image_rule'
        autoload :FootnoteRule, 'coridoc/docx/transform/rules/footnote_rule'
        autoload :HeadingRule, 'coridoc/docx/transform/rules/heading_rule'
        autoload :ListItemRule, 'coridoc/docx/transform/rules/list_item_rule'
        autoload :ParagraphRule, 'coridoc/docx/transform/rules/paragraph_rule'
        autoload :TableRule, 'coridoc/docx/transform/rules/table_rule'
        autoload :MathRule, 'coridoc/docx/transform/rules/math_rule'
        autoload :BookmarkRule, 'coridoc/docx/transform/rules/bookmark_rule'
        autoload :StructuredDocumentTagRule,
                 'coridoc/docx/transform/rules/structured_document_tag_rule'
        autoload :SimpleFieldRule,
                 'coridoc/docx/transform/rules/simple_field_rule'
        autoload :ProofErrorRule,
                 'coridoc/docx/transform/rules/proof_error_rule'
      end
    end
  end
end
