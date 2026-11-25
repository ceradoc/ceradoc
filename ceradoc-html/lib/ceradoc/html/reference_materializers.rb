# frozen_string_literal: true

module Ceradoc
  module Html
    # Materializers rendering resolved reference Edges into
    # HTML-shaped CoreModel nodes. They live in the format gem (not
    # ceradoc core) so format knowledge stays at the spoke of the
    # hub-and-spoke architecture; registration is a load-time side
    # effect via the Materializer registry's global extension point.
    module ReferenceMaterializers
      autoload :Navigation, 'ceradoc/html/reference_materializers/navigation'
      autoload :Link, 'ceradoc/html/reference_materializers/link'
    end
  end
end

Ceradoc::Reference::Materializer::Registry.register_global(
  Ceradoc::Html::ReferenceMaterializers::Navigation
)
Ceradoc::Reference::Materializer::Registry.register_global(
  Ceradoc::Html::ReferenceMaterializers::Link
)
