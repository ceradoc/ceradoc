# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Lint
      # ADOC003 — sections should carry content: neither block
      # content nor subsections means an empty heading.
      class EmptySection < Coridoc::Lint::Rule
        rule_id 'ADOC003'
        applies_to :asciidoc

        def check(document, path)
          violations = []
          walk(document, path, violations)
          violations
        end

        private

        def walk(node, path, violations)
          Array(node.sections).each do |child|
            case child
            when Coridoc::AsciiDoc::Model::Section
              if empty?(child)
                violations << build_violation(
                  path: path,
                  message: "empty section: #{child.title&.content}"
                )
              end
              walk(child, path, violations)
            end
          end
        end

        def empty?(section)
          Array(section.contents).empty? && sections_of(section).empty?
        end

        def sections_of(section)
          Array(section.sections).grep(Coridoc::AsciiDoc::Model::Section)
        end
      end
    end
  end
end
