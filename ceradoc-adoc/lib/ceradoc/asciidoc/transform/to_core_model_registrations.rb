# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Transform
      module ToCoreModelRegistrations
        Doc = ElementTransformers::DocumentTransformer
        Blk = ElementTransformers::BlockTransformer
        Lst = ElementTransformers::ListTransformer
        Inl = ElementTransformers::InlineTransformer
        Tbl = ElementTransformers::TableTransformer
        Oth = ElementTransformers::OtherTransformer
        Inc = ElementTransformers::IncludeTransformer

        class << self
          def register_all!
            register_document_transformers!
            register_block_transformers!
            register_list_transformers!
            register_inline_transformers!
            register_table_transformers!
            register_other_transformers!
          end

          private

          def register_document_transformers!
            Registry.register(
              Ceradoc::AsciiDoc::Model::Document,
              ->(model) { Doc.transform_document(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Section,
              ->(model) { Doc.transform_section(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Paragraph,
              ->(model) { Blk.transform_paragraph(model) }
            )
          end

          def register_block_transformers!
            Registry.register_with_priority(
              Ceradoc::AsciiDoc::Model::Block::SourceCode,
              ->(model) { Blk.transform_source_block(model) },
              priority: 10
            )

            # Quote / Example / Sidebar blocks all share the same dispatch:
            # check the attribute style for an admonition label first
            # (`[NOTE]\n====` → AnnotationBlock), fall back to the block's
            # native CoreModel type. Single source of truth lives in
            # BlockTransformer#transform_with_admonition_check.
            {
              Ceradoc::AsciiDoc::Model::Block::Quote => :transform_quote_block,
              Ceradoc::AsciiDoc::Model::Block::Example => :transform_example_block,
              Ceradoc::AsciiDoc::Model::Block::Side => :transform_sidebar_block
            }.each do |block_class, method|
              Registry.register_with_priority(
                block_class,
                ->(model) { Blk.public_send(method, model) },
                priority: 10
              )
            end

            # Verbatim typed blocks (literal, pass) preserve their body
            # byte-for-byte — same line-joining strategy as source/listing.
            # Routing them through `transform_typed_block` would collapse
            # intra-block whitespace and join consecutive lines as paragraphs.
            Registry.register_with_priority(
              Ceradoc::AsciiDoc::Model::Block::Literal,
              ->(model) { Blk.transform_literal_block(model) },
              priority: 10
            )

            Registry.register_with_priority(
              Ceradoc::AsciiDoc::Model::Block::Pass,
              ->(model) { Blk.transform_pass_block(model) },
              priority: 10
            )

            Registry.register_with_priority(
              Ceradoc::AsciiDoc::Model::Block::Open,
              ->(model) { Blk.transform_open_block(model) },
              priority: 10
            )

            Registry.register_with_priority(
              Ceradoc::AsciiDoc::Model::Block::ReviewerComment,
              ->(model) { Blk.transform_reviewer_block(model) },
              priority: 10
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Block::Core,
              ->(model) { Blk.transform_block(model, model.delimiter.to_s) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::CommentBlock,
              lambda { |model|
                Ceradoc::CoreModel::CommentBlock.new(
                  content: model.text.to_s
                )
              }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::CommentLine,
              lambda { |model|
                Ceradoc::CoreModel::CommentLine.new(
                  text: model.text.to_s
                )
              }
            )
          end

          def register_list_transformers!
            Registry.register(
              Ceradoc::AsciiDoc::Model::List::Unordered,
              ->(model) { Lst.transform_list(model, 'unordered') }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::List::Ordered,
              ->(model) { Lst.transform_list(model, 'ordered') }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::List::Definition,
              ->(model) { Lst.transform_list(model, 'definition') }
            )
          end

          def register_inline_transformers!
            [
              [Ceradoc::AsciiDoc::Model::Inline::Bold, 'bold'],
              [Ceradoc::AsciiDoc::Model::Inline::Italic, 'italic'],
              [Ceradoc::AsciiDoc::Model::Inline::Monospace, 'monospace'],
              [Ceradoc::AsciiDoc::Model::Inline::Highlight, 'highlight'],
              [Ceradoc::AsciiDoc::Model::Inline::Strikethrough, 'strikethrough'],
              [Ceradoc::AsciiDoc::Model::Inline::Subscript, 'subscript'],
              [Ceradoc::AsciiDoc::Model::Inline::Superscript, 'superscript']
            ].each do |inline_class, format_type|
              Registry.register(
                inline_class,
                ->(model) { Inl.transform_inline(model, format_type) }
              )
            end

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::Underline,
              ->(model) { Inl.transform_inline_text(model, 'underline') }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::Link,
              ->(model) { Inl.transform_link(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::CrossReference,
              ->(model) { Inl.transform_cross_reference(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::Footnote,
              ->(model) { Inl.transform_inline_footnote(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::Stem,
              ->(model) { Inl.transform_stem(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::AttributeReference,
              lambda { |model|
                name = model.name.to_s
                Ceradoc::CoreModel::InlineElement.new(
                  format_type: 'attribute_reference',
                  target: name,
                  content: "{#{name}}"
                )
              }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::Passthrough,
              lambda { |model|
                Ceradoc::CoreModel::RawInlineElement.new(
                  content: model.content.to_s
                )
              }
            )
          end

          def register_table_transformers!
            Registry.register(
              Ceradoc::AsciiDoc::Model::Table,
              ->(model) { Tbl.transform_table(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::TableRow,
              ->(model) { Tbl.transform_table_row(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::TableCell,
              ->(model) { Tbl.transform_table_cell(model) }
            )
          end

          def register_other_transformers!
            Registry.register(
              Ceradoc::AsciiDoc::Model::Term,
              ->(model) { Oth.transform_term(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Admonition,
              ->(model) { Oth.transform_admonition(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Image::BlockImage,
              ->(model) { Oth.transform_image(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Image::InlineImage,
              ->(model) { Oth.transform_image(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::Bibliography,
              ->(model) { Oth.transform_bibliography(model) }
            )

            Registry.register(
              Ceradoc::AsciiDoc::Model::BibliographyEntry,
              ->(model) { Oth.transform_bibliography_entry(model) }
            )

            # Include directives become first-class CoreModel::Include nodes
            # (link edges in a text graph). To splice their content inline,
            # call +Ceradoc.resolve_includes(doc, base_dir:)+ on the parsed
            # document — that step is intentionally separate from parse.
            Registry.register(
              Ceradoc::AsciiDoc::Model::Include,
              ->(model) { Inc.transform_include(model) }
            )

            # Inline hard line break — distinct from the structural
            # Model::LineBreak (which represents paragraph-separator blank
            # lines and is dropped at the CoreModel boundary). Hard breaks
            # are semantic and round-trip as CoreModel::HardLineBreakElement
            # so HTML/Markdown renderers can map them to <br>.
            Registry.register(
              Ceradoc::AsciiDoc::Model::Inline::HardLineBreak,
              ->(_model) { Ceradoc::CoreModel::HardLineBreakElement.new(content: '') }
            )

            [
              Ceradoc::AsciiDoc::Model::Audio,
              Ceradoc::AsciiDoc::Model::Video,
              Ceradoc::AsciiDoc::Model::ContentList,
              Ceradoc::AsciiDoc::Model::Tag,
              Ceradoc::AsciiDoc::Model::LineBreak,
              Ceradoc::AsciiDoc::Model::Break::PageBreak
            ].each do |klass|
              Registry.register(klass, ->(_model) {})
            end
          end
        end
      end
    end
  end
end
