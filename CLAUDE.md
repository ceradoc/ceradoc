# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ceradoc is a Ruby hub-and-spoke document transformation library. A canonical `CoreModel` serves as the central hub, and format-specific gems (AsciiDoc, HTML, Markdown) are spokes. Adding a new format requires only two transformers (ToCoreModel, FromCoreModel).

## Monorepo Structure

- **`ceradoc/`** — Core gem: `CoreModel`, `Registry`, `Transform::Base`, hooks, validation, streaming, query API
- **`ceradoc-adoc/`** — AsciiDoc gem: Parslet-based parser, document model, serializer, transformer (ToCoreModel/FromCoreModel)
- **`ceradoc-html/`** — HTML gem: Leptris-based converter, classic renderer, Vue.js SPA theme
- **`ceradoc-markdown/`** — Markdown gem: Parslet-based CommonMark parser, document model, serializer
- **`ceradoc-docx/`** — DOCX gem: Uniword-based OOXML transformer

Each gem has its own gemspec, `lib/`, `spec/`, and `Rakefile`. All are loaded together via the root `Gemfile` using `path:` references. Run `rake spec` inside any gem directory for standalone specs.

## Build & Test Commands

```bash
bundle install              # Install dependencies (all gems together)

# Tests (from monorepo root)
bundle exec rake spec_all                  # Run ALL gem specs (main + sub-gems)
bundle exec rake spec:ceradoc              # Run only ceradoc specs
bundle exec rake spec:ceradoc_adoc         # Run only ceradoc-adoc specs
bundle exec rake spec:ceradoc_html         # Run only ceradoc-html specs
bundle exec rake spec:ceradoc_markdown     # Run only ceradoc-markdown specs
bundle exec rake spec:ceradoc_docx         # Run only ceradoc-docx specs

# Tests (from inside a gem directory)
cd ceradoc && bundle exec rake spec        # Run ceradoc specs standalone
cd ceradoc-adoc && bundle exec rake spec   # Run adoc specs standalone

# Linting
bundle exec rubocop

# Console
bundle exec rake console     # IRB with ceradoc preloaded
```

## Architecture

### CoreModel (`ceradoc/lib/ceradoc/core_model.rb`)

The canonical document representation using `lutaml-model`. Key types: `StructuralElement`, `Block`, `ListBlock`, `ListItem`, `InlineElement`, `Table`, `Image`, `Metadata`, `Footnote`, `DefinitionList`, `Bibliography`. All inherit from `CoreModel::Base`.

### Transformation Flow

```
Source text → Format::Parser → Format Model → ToCoreModel → CoreModel → FromCoreModel → Target Model → Serialize → Target text
```

- `Ceradoc.convert(text, from: :asciidoc, to: :html)` — end-to-end conversion
- `Ceradoc.parse(text, format:)` — parse to CoreModel
- `Ceradoc.serialize(core, to:)` — serialize CoreModel to output

### Format Registration

Format gems register via `Ceradoc.register_format(:name, Module)` and must implement `parse_to_core`/`parse` and `serialize`. The `Registry` class in `ceradoc/lib/ceradoc/registry.rb` manages this.

### AsciiDoc Gem Internals

- **Parser** (`ceradoc-adoc/lib/ceradoc/asciidoc/parser/`) — Parslet-based, rule files: `header`, `inline`, `block`, `list`, `section`, `table`, `bibliography`, `citation`, `stem`, `admonition`
- **Model** (`ceradoc-adoc/lib/ceradoc/asciidoc/model/`) — ~40+ model classes inheriting from `Model::Base`, built with `lutaml-model`
- **Serializer** (`ceradoc-adoc/lib/ceradoc/asciidoc/serializer/`) — Converts AsciiDoc models back to `.adoc` strings via element-specific serializer classes
- **Transformer** (`ceradoc-adoc/lib/ceradoc/asciidoc/transformer.rb`) — Parslet `Transform` subclass with rule modules (HeaderRules, InlineRules, etc.)
- **Transform** (`ceradoc-adoc/lib/ceradoc/asciidoc/transform/`) — `ToCoreModel` and `FromCoreModel` with registration-based dispatch

### Key Dependencies

- `lutaml-model` — serialization framework for model classes (used by CoreModel and AsciiDoc model)
- `parslet` — PEG parser (used by AsciiDoc and Markdown parsers; Parsanol migration in flight — see the `wip/parsanol-migration` branch and parsanol-ruby#67)
- `leptris` — Leptris::XML FFI binding: HTML parsing + DOM + serialization (used by the HTML gem). Parse via the `Leptris::HTML` facade (`Leptris::HTML.parse` = html4/Nokogiri-parity lane, `Leptris::HTML5.parse` = WHATWG; selected with the `html_version:` input option). Native binaries are signed as of leptris 1.9.334; set `LEPTRIS_NO_NATIVE=1` only to force the pure-Ruby fallback
- `thor` — CLI framework

## Conventions

- **Release only on user request**: Never trigger gem releases or version bumps autonomously. Only release when the user explicitly asks for it.
- **NO HASHES IN MODELS**: CoreModel classes must NEVER use `:hash` as an attribute type. Every attribute must be a typed model, string, integer, or array of typed models. No hash bags, no generic key-value stores. This enforces the model-driven architecture.
- **NO SERIALIZATION IN MODELS**: CoreModel classes must NEVER contain `to_hash`, `to_json`, `serialize`, or any custom serialization methods. Models are pure data structures. Serialization is handled by dedicated serializer classes (lutaml-model handles this automatically).
- **NO RAW HTML STRINGS**: The HTML gem must use Leptris::XML as both the model layer AND the HTML builder. Never concatenate raw HTML strings. Never manually construct HTML in text. Use `Ceradoc::Html::Builder` or `Leptris::XML` node methods to construct HTML output. ALL non-model-driven HTML construction code must be converted to the Builder.
- **Model classes own only their native format**: No `to_adoc` in Markdown models, no `to_md` in AsciiDoc models. Cross-format conversion always routes through CoreModel transformers (ToCoreModel / FromCoreModel). This enforces SRP, OCP, and DIP.
- **Autoload over require_relative**: Use `autoload` with `#{__dir__}` paths (see `core_model.rb` for pattern). Exception: files with load-time side effects (registrations, `apply` calls) use `require_relative`.
- **Error-raising in serializers**: Unknown types in `serialize_content` should raise `ArgumentError`, never fall back to `to_s`. This catches missing serializers immediately rather than producing Ruby object dumps.
- **Ruby 3.3+ target**, `TargetRubyVersion: 3.3` in RuboCop.
- RSpec uses `--format documentation`, `--color`, `expect` syntax, `disable_monkey_patching!`.
- Benchmark tests are excluded unless `BENCHMARK=true`.
