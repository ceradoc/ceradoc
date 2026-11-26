# frozen_string_literal: true

module Ceradoc
  module Lint
    # The INC rule family (#380): findings on the include graph, emitted
    # by {Ceradoc::ResolveIncludes} while it resolves. They live in the
    # Lint namespace because their findings are Diagnostics (#377) —
    # identity is the stable rule code, position rides +anchor+ (the
    # including file) and +line+ (the include directive's source line).
    #
    #   INC001  the include target could not be turned into content:
    #           the file is missing, or its extension has no registered
    #           parseable format so dispatch falls back to the host
    #           format
    #   INC002  the include graph has a cycle (self-include or loop);
    #           emitted right before the CircularIncludeError is raised
    #   INC003  format-policy mismatch: the target's format is not in
    #           the +include_formats+ allowlist; the directive is left
    #           in place and its content is NOT spliced. Without an
    #           allowlist this rule stays silent.
    #
    # These rules are emitted by the resolver, not run by the lint
    # Runner over format trees — they declare the pseudo-format
    # +:include+, which no file ever detects to, so
    # +Ceradoc::Lint.run+ never picks them up.
    module IncludeRules
      # Missing or undispatchable include target.
      class MissingInclude < Rule
        rule_id 'INC001'
        applies_to :include
      end

      # Circular include; emitted before the resolver raises.
      class CircularInclude < Rule
        rule_id 'INC002'
        applies_to :include
      end

      # Target format outside the +include_formats+ allowlist.
      class FormatPolicyMismatch < Rule
        rule_id 'INC003'
        applies_to :include
      end

      RULES = [MissingInclude, CircularInclude, FormatPolicyMismatch].freeze

      class << self
        # Build one finding in the diagnostic currency. +anchor+ is the
        # including file's path; +line+ is the include directive's
        # source line when the parser recorded one.
        def diagnostic(rule, include_node:, anchor:, message:, severity: 'error')
          rule.new.build_diagnostic(
            path: anchor,
            message: message,
            line: include_node.source_line,
            severity: severity
          )
        end

        # Register the family with the lint registry. Called when the
        # registry is first created so the INC codes are discoverable
        # through +Ceradoc::Lint.registry+ without resolving anything.
        def register_all(registry)
          RULES.each { |rule| registry.register(rule) }
          registry
        end
      end
    end
  end
end
