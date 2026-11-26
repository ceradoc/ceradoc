# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      # Registers all default CoreModel -> AsciiDoc transformers
      module FromCoreModelRegistrations
        class << self
          def register_all!
            register_structural_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
            register_other_transformers!
          end

          private

          def register_structural_transformers!
            Registry.register(
              Ceradoc::CoreModel::StructuralElement,
              ->(model) { FromCoreModel.transform_structural_element(model) }
            )
          end

          def register_block_transformers!
            # ReviewerBlock BEFORE AnnotationBlock: both are priority 10,
            # the lookup takes the first subclass match, so the reviewer
            # must win its own dispatch — otherwise it degrades to a
            # REVIEWER: admonition line (#376).
            Registry.register_with_priority(
              Ceradoc::CoreModel::ReviewerBlock,
              ->(model) { FromCoreModel.transform_block(model) },
              priority: 10
            )

            Registry.register_with_priority(
              Ceradoc::CoreModel::AnnotationBlock,
              ->(model) { FromCoreModel.transform_annotation(model) },
              priority: 10
            )

            Registry.register(
              Ceradoc::CoreModel::Block,
              ->(model) { FromCoreModel.transform_block(model) }
            )
          end

          def register_list_transformers!
            Registry.register(
              Ceradoc::CoreModel::ListBlock,
              ->(model) { FromCoreModel.transform_list(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::ListItem,
              ->(model) { FromCoreModel.transform_list_item(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::DefinitionList,
              ->(model) { FromCoreModel.transform_definition_list(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::DefinitionItem,
              ->(model) { FromCoreModel.transform_definition_item(model) }
            )
          end

          def register_inline_transformers!
            Registry.register(
              Ceradoc::CoreModel::InlineElement,
              ->(model) { FromCoreModel.transform_inline(model) }
            )
          end

          def register_other_transformers!
            Registry.register(
              Ceradoc::CoreModel::Table,
              ->(model) { FromCoreModel.transform_table(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Term,
              ->(model) { FromCoreModel.transform_term(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Image,
              ->(model) { FromCoreModel.transform_image(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Footnote,
              ->(model) { FromCoreModel.transform_footnote(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::FootnoteReference,
              ->(model) { FromCoreModel.transform_footnote_reference(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Abbreviation,
              ->(model) { FromCoreModel.transform_abbreviation(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Toc,
              ->(model) { FromCoreModel.transform_toc(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::TocEntry,
              ->(model) { FromCoreModel.transform_toc_entry(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Bibliography,
              ->(model) { FromCoreModel.transform_bibliography(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::BibliographyEntry,
              ->(model) { FromCoreModel.transform_bibliography_entry(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::CommentLine,
              ->(model) { FromCoreModel.transform_comment_line(model) }
            )

            Registry.register(
              Ceradoc::CoreModel::Include,
              ->(model) { FromCoreModel.transform_include(model) }
            )
          end
        end
      end
    end
  end
end

# Auto-register when this file is loaded
