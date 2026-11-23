# frozen_string_literal: true

module Coridoc
  module Html
    # Materializers rendering resolved reference Edges into
    # HTML-shaped CoreModel nodes. They live in the format gem (not
    # coridoc core) so format knowledge stays at the spoke of the
    # hub-and-spoke architecture; registration is a load-time side
    # effect via the Materializer registry's global extension point.
    module ReferenceMaterializers
      autoload :Navigation, 'coridoc/html/reference_materializers/navigation'
      autoload :Link, 'coridoc/html/reference_materializers/link'
    end
  end
end

Coridoc::Reference::Materializer::Registry.register_global(
  Coridoc::Html::ReferenceMaterializers::Navigation
)
Coridoc::Reference::Materializer::Registry.register_global(
  Coridoc::Html::ReferenceMaterializers::Link
)
