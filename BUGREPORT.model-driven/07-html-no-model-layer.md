# 07: HTML gem completely bypasses hub-and-spoke architecture

## Status: NOT FIXED

- HTML gem still directly consumes CoreModel types throughout (~80 files, 435+ CoreModel references)
- No HTML-specific model layer exists
- `ToCoreModel` and `FromCoreModel` transformers remain pass-throughs
- Requires 80+ file rewrite — deferred to a separate PR


**Severity:** CRITICAL  
**Location:** Entire `ceradoc-html/lib/` tree (~80 files, 435+ CoreModel references)

## Problem

The HTML gem has no format-specific model layer. Every component — input converters, output converters, renderer, element_mapping, and theme system — operates directly on `CoreModel::*` types. The `ToCoreModel` and `FromCoreModel` transformers are pass-throughs that return their input unchanged.

This means the HTML gem is not a "spoke" — it is a direct consumer of the hub, completely violating the hub-and-spoke architecture that ADOC, Markdown, and DOCX gems follow.

## Evidence

### 7A. No model directory exists
No `ceradoc-html/lib/ceradoc/html/model/` directory. Zero HTML-specific model classes.

### 7B. Both transformers are pass-throughs
- `transform/to_core_model.rb:22-29` — returns `model` if `is_a?(CoreModel::Base)`
- `transform/from_core_model.rb:17-27` — returns CoreModel object unchanged. Comment: "HTML converters already support CoreModel directly."

### 7C. Input converters directly instantiate CoreModel (67 refs, 30 files)
All files in `input/converters/` create CoreModel instances:
- `p.rb:15` — `CoreModel::Block.new(element_type: 'paragraph', ...)`
- `h.rb:22` — `CoreModel::StructuralElement.new(...)`
- `table.rb:17` — `CoreModel::Table.new(...)`
- `text.rb:15` — `CoreModel::InlineElement.new(...)`
- Plus 26 more converters

### 7D. Output converters directly consume CoreModel (195 refs, 50 files)
`converters/base.rb:48-106` — 25 consecutive `is_a?(Ceradoc::CoreModel::*)` checks:
```ruby
when Ceradoc::CoreModel::InlineElement
when Ceradoc::CoreModel::AnnotationBlock
when Ceradoc::CoreModel::Block
# ... 22 more
```
Lines 111-207 directly access CoreModel attributes (`format_type`, `block_semantic_type`, `content`, `target`).

### 7E. `element_mapping.rb` maps HTML tags to CoreModel class name strings
Lines 107-166:
```ruby
HTML_TO_MODEL = {
  p: 'Ceradoc::CoreModel::Block',
  section: 'Ceradoc::CoreModel::StructuralElement',
  table: 'Ceradoc::CoreModel::Table',
  img: 'Ceradoc::CoreModel::Image',
  h1: 'Ceradoc::CoreModel::StructuralElement',
  # ... 50+ more
}
```

### 7F. Renderer dispatches on CoreModel class names
`renderer.rb:40-72` — `TEMPLATE_TYPE_MAP`:
```ruby
'Ceradoc::CoreModel::Bibliography' => 'bibliography',
'Ceradoc::CoreModel::Block' => 'block',
'Ceradoc::CoreModel::SourceBlock' => 'source_block',
# ...
```
Line 400: `element.is_a?(Ceradoc::CoreModel::StructuralElement)`

### 7G. ConverterBase enforces CoreModel-only input
`converter_base.rb:106-111`:
```ruby
unless document.is_a?(Ceradoc::CoreModel::Base)
  raise UnsupportedDocumentError,
    "Expected CoreModel document, got: #{document.class}."
end
```

### 7H. Theme system references CoreModel types
- `theme/classic_renderer.rb` — 6 `is_a?(CoreModel::*)` checks
- `theme/modern/serializers/document_serializer.rb:24` — validates `CoreModel::StructuralElement`
- `renderer.rb:229-233` — iterates `CoreModel.constants(false)` to create Liquid drops

### 7I. Top-level `html.rb` rejects non-CoreModel input
Lines 92-99:
```ruby
unless document.is_a?(Ceradoc::CoreModel::Base)
  raise ArgumentError, 'ceradoc-html only accepts CoreModel types.'
end
```

## Impact

Any CoreModel attribute change requires updating ~80 files in the HTML gem. The HTML gem cannot be tested or developed independently of CoreModel.

## Fix

Create an HTML model layer under `ceradoc-html/lib/ceradoc/html/model/` with HTML-native types. Implement proper ToCoreModel (HTML models → CoreModel) and FromCoreModel (CoreModel → HTML models) transformers. All converters, renderers, and serializers work only with HTML model types.
