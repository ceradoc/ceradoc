# frozen_string_literal: true

require 'lutaml/model'

module Coridoc
  module Reference
    module Presentation
      # A page is the unit of output a Presentation produces. One HTML
      # file, one PDF page, one EPUB chapter — same data, different
      # materialization. The Materializer consumes Pages.
      class Page < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :title, :string
        attribute :content, Coridoc::CoreModel::Base
        attribute :parent_id, :string
        attribute :order, :integer
      end
    end
  end
end
