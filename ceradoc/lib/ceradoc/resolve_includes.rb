# frozen_string_literal: true

module Ceradoc
  # Flat-mode include processor — the explicit "flatten" step.
  #
  # Walks a parsed CoreModel and expands every {CoreModel::Include} link
  # node into the parsed content of its target, recursing into the result.
  # The original CoreModel is NOT modified — a new subtree is constructed
  # and spliced into place.
  #
  # Invoked via the public API +Ceradoc.resolve_includes(doc, base_dir:)+.
  # Callers control resolution strategy (filesystem, HTTP, custom),
  # missing-include policy, recursion depth, and path-traversal safety.
  #
  # Honors:
  #   - mixed-format dispatch: the target's EXTENSION selects the
  #     parsing format through the format registry (#380) — a +.md+
  #     target inside an +.adoc+ tree splices markdown-parsed
  #     CoreModel, and the reverse. An extension no registered format
  #     claims emits an INC001 diagnostic and falls back to +parse_format+
  #     (the pre-dispatch behavior). Format gems must be required (or
  #     loadable) — extension detection only sees registered formats,
  #     like the rest of Ceradoc.
  #   - +include_formats+ allowlist: when passed (e.g.
  #     +%i[asciidoc markdown]+), a target whose detected format is not
  #     in the list emits INC003 and the directive is left in place —
  #     its content is NOT spliced. Without the option INC003 stays
  #     silent and every dispatchable target resolves.
  #   - +missing_include+ policy: :error (default) | :warn | :silent | :passthrough
  #   - +max_depth+ limit (raises Ceradoc::IncludeDepthExceededError)
  #   - circular detection (raises Ceradoc::CircularIncludeError)
  #   - tags/lines/indent selectors (applied to raw text before parse)
  #   - leveloffset selector (applied to parsed CoreModel)
  #   - +base_dir+ re-rooting (recursive includes resolve relative to
  #     the including file — SPEC 7.2)
  #
  # Diagnostics ride the #377 currency (Lint::Diagnostic) under the INC
  # rule family (Lint::IncludeRules): INC001 unresolvable target
  # (missing file / unknown extension), INC002 cycle, INC003 policy
  # mismatch. Pass +diagnostics:+ (an array you own) to collect them
  # alongside the resolved document; the resolved document remains the
  # return value, so the existing result shape is unchanged. The array
  # is filled as resolution proceeds, so it stays readable from a
  # +rescue+ around a raising policy.
  #
  # Resolution is a VIEW. Write-back writes FILES: the input document
  # keeps its Include edges, so serializing the host (in its own
  # format) still emits the include directive, and each part serializes
  # in its own format — spliced content is never inlined into the host
  # text. Pass +source_path:+ (the host document's path) so diagnostic
  # anchors point at the including file.
  class ResolveIncludes
    DEFAULT_MAX_DEPTH = 64

    attr_reader :diagnostics

    class << self
      def call(core, resolver:, base_dir:, **)
        new(resolver: resolver, base_dir: base_dir, **).call(core)
      end
    end

    # @param resolver [#call] anything responding to +#call(target:, base_dir:, options:, context:)+
    # @param base_dir [String] absolute path to the document root directory
    # @param missing_include [Symbol] :error | :warn | :silent | :passthrough
    # @param max_depth [Integer] recursion cap
    # @param parse_format [Symbol] fallback format when the extension
    #   dispatch finds no registered parseable format
    # @param include_formats [Array<Symbol, String>, nil] allowlist of
    #   includeable formats; nil disables the policy (INC003 silent)
    # @param source_path [String, nil] path of the host document, used
    #   as the diagnostic anchor for top-level includes
    # @param diagnostics [Array, nil] caller-owned array the INC
    #   diagnostics are appended to
    def initialize(resolver:, base_dir:,
                   missing_include: :error,
                   max_depth: DEFAULT_MAX_DEPTH,
                   parse_format: :asciidoc,
                   include_formats: nil,
                   source_path: nil,
                   diagnostics: nil)
      @resolver = Ceradoc::IncludeResolver.coerce(resolver, base_dir: base_dir)
      @base_dir = base_dir
      @missing_policy = missing_include
      @max_depth = max_depth
      @parse_format = parse_format
      @include_formats = include_formats && Array(include_formats).map { |f| FormatCatalog.normalize_format(f) }
      @source_path = source_path && File.expand_path(source_path)
      @diagnostics = diagnostics || []
    end

    # Walk + transform. Returns a NEW CoreModel with includes expanded.
    # The cycle chain is seeded with the host document's path when known,
    # so a self-include is caught on the first pass.
    def call(core)
      expand_node(core, base_dir: File.expand_path(@base_dir),
                        chain: @source_path ? [@source_path] : [], depth: 0,
                        current_file: @source_path)
    end

    private

    def expand_node(node, base_dir:, chain:, depth:, current_file:)
      return node unless node.is_a?(Ceradoc::CoreModel::Base)

      case node
      when Ceradoc::CoreModel::Include
        expand_include(node, base_dir: base_dir, chain: chain, depth: depth,
                             current_file: current_file)
      when Ceradoc::CoreModel::StructuralElement, Ceradoc::CoreModel::Block
        expand_container(node, base_dir: base_dir, chain: chain, depth: depth,
                               current_file: current_file)
      else
        node
      end
    end

    def expand_container(node, base_dir:, chain:, depth:, current_file:)
      return node if node.children.nil? || node.children.empty?

      expanded_children = node.children.flat_map do |child|
        expanded = expand_node(child, base_dir: base_dir, chain: chain, depth: depth,
                                      current_file: current_file)
        Array(expanded)
      end

      return node if expanded_children.equal?(node.children) || same_children?(expanded_children, node.children)

      duplicate_with_children(node, expanded_children)
    end

    # The processor must not mutate its input. Each container that has
    # expanded includes is replaced by a shallow copy with a new
    # +children+ array — the original document tree stays intact so the
    # caller can re-resolve with different options.
    def duplicate_with_children(node, new_children)
      duplicate = node.dup
      duplicate.children = new_children
      duplicate
    end

    def same_children?(expanded, original)
      return false unless expanded.length == original.length

      expanded.each_with_index.all? { |node, i| node.equal?(original[i]) }
    end

    def expand_include(include_node, base_dir:, chain:, depth:, current_file:)
      enforce_depth!(include_node, depth)

      full_target = resolve_target_path(include_node.target, base_dir)
      enforce_cycle!(include_node, full_target: full_target, chain: chain,
                                   current_file: current_file)

      format = dispatch_format(include_node, full_target: full_target, anchor: anchor_for(current_file))
      return include_node if format.nil? # policy-blocked: directive stays put

      new_chain = chain + [full_target]

      content = fetch_content(include_node, base_dir: base_dir, anchor: anchor_for(current_file))
      return replacement_for_missing(include_node) if missing_content?(content)

      applied = apply_text_selectors(content, include_node.options)
      parsed = parse_included(applied, format)

      shifted = Ceradoc::IncludeSelectors::LevelOffset.call(parsed, options: include_node.options)

      new_base_dir = File.dirname(full_target)
      expand_subtree(shifted, base_dir: new_base_dir, chain: new_chain, depth: depth + 1,
                              current_file: full_target)
    end

    def missing_content?(content)
      content.nil? || content == :passthrough
    end

    def fetch_content(include_node, base_dir:, anchor:)
      @resolver.call(
        target: include_node.target,
        base_dir: base_dir,
        options: include_node.options,
        context: {}
      )
    rescue Ceradoc::IncludeNotFoundError => e
      emit_missing_diagnostic(include_node, anchor: anchor, message: "include target not found: #{include_node.target}")
      handle_missing(include_node, e)
    end

    def handle_missing(include_node, error)
      case @missing_policy
      when :error then raise error
      when :warn
        Ceradoc::Logger.warn("Include target not found: #{include_node.target}")
        nil
      when :silent then nil
      when :passthrough then :passthrough
      else raise error
      end
    end

    def replacement_for_missing(include_node)
      return [include_node] if @missing_policy == :passthrough

      []
    end

    # Mixed-format dispatch (#380): the target's extension selects the
    # parsing format through the format registry. Returns nil when the
    # include_formats policy rejects the target (INC003 emitted, the
    # directive stays in place).
    def dispatch_format(include_node, full_target:, anchor:)
      detected = FormatCatalog.detect_format(full_target)

      if @include_formats
        return policy_mismatch(include_node, anchor: anchor, detected: detected) unless policy_allows?(detected)

        return detected
      end

      return detected if parseable_format?(detected)

      emit_unknown_extension_diagnostic(include_node, anchor: anchor, detected: detected)
      @parse_format
    end

    def policy_allows?(detected)
      !detected.nil? && @include_formats.include?(detected)
    end

    def policy_mismatch(include_node, anchor:, detected:)
      label = detected ? "format :#{detected}" : 'no registered format'
      Lint::IncludeRules.diagnostic(
        Lint::IncludeRules::FormatPolicyMismatch,
        include_node: include_node,
        anchor: anchor,
        message: "include target #{include_node.target} resolves to #{label}, " \
                 'which is not in the include_formats allowlist ' \
                 "(#{@include_formats.map(&:inspect).join(', ')})"
      ).tap { |d| @diagnostics << d }
      nil
    end

    def emit_unknown_extension_diagnostic(include_node, anchor:, detected:)
      message = if detected
                  "format :#{detected} cannot parse include target #{include_node.target}; " \
                    "falling back to :#{@parse_format}"
                else
                  "no registered format for the extension of #{include_node.target}; " \
                    "falling back to :#{@parse_format}"
                end
      Lint::IncludeRules.diagnostic(
        Lint::IncludeRules::MissingInclude,
        include_node: include_node,
        anchor: anchor,
        message: message,
        severity: 'warning'
      ).tap { |d| @diagnostics << d }
    end

    def emit_missing_diagnostic(include_node, anchor:, message:)
      Lint::IncludeRules.diagnostic(
        Lint::IncludeRules::MissingInclude,
        include_node: include_node,
        anchor: anchor,
        message: message,
        severity: @missing_policy == :error ? 'error' : 'warning'
      ).tap { |d| @diagnostics << d }
    end

    # The anchor is the including file; the resolver only knows the
    # root document's path (+source_path+) and, deeper in the tree,
    # the chain of resolved targets — the last chain entry is the file
    # whose content contains the directive.
    def anchor_for(current_file)
      current_file || @base_dir
    end

    def parseable_format?(format)
      return false if format.nil?

      FormatCatalog.parse_format?(format) && !FormatCatalog.binary_format?(format)
    end

    def apply_text_selectors(text, options)
      text = apply_lines_or_tags(text, options)
      Ceradoc::IncludeSelectors::Indent.call(text, options: options)
    end

    def apply_lines_or_tags(text, options)
      # lines wins when both specified (SPEC 3.5)
      return Ceradoc::IncludeSelectors::Lines.call(text, options: options) if options.lines?

      Ceradoc::IncludeSelectors::Tags.call(text, options: options)
    end

    def parse_included(text, format)
      return empty_core if text.nil? || text.empty?

      Ceradoc.parse(text, format: format)
    end

    def empty_core
      Ceradoc::CoreModel::DocumentElement.new
    end

    def expand_subtree(core, base_dir:, chain:, depth:, current_file:)
      expanded = expand_node(core, base_dir: base_dir, chain: chain, depth: depth,
                                   current_file: current_file)
      return [expanded] unless expanded.is_a?(Ceradoc::CoreModel::StructuralElement)

      expanded.children || []
    end

    def enforce_depth!(include_node, depth)
      return if depth < @max_depth

      raise Ceradoc::IncludeDepthExceededError.new(
        target: include_node.target,
        depth: depth,
        max: @max_depth
      )
    end

    def enforce_cycle!(include_node, full_target:, chain:, current_file:)
      return unless chain.include?(full_target)

      Lint::IncludeRules.diagnostic(
        Lint::IncludeRules::CircularInclude,
        include_node: include_node,
        anchor: anchor_for(current_file),
        message: "circular include: #{include_node.target} is already in the " \
                 "include chain (#{chain.map { |p| File.basename(p) }.join(' -> ')})"
      ).tap { |d| @diagnostics << d }

      raise Ceradoc::CircularIncludeError.new(
        target: include_node.target,
        chain: chain
      )
    end

    def resolve_target_path(target, base_dir)
      File.expand_path(target, base_dir)
    end
  end
end
