# frozen_string_literal: true

require 'leptris'
require 'ceradoc'

module Ceradoc
  module Html
    module Transform
      # Transforms Leptris HTML nodes to CoreModel
      #
      # Leptris serves as the HTML model layer. This transformer converts
      # Leptris::XML::Document or Leptris::XML::Node objects into CoreModel
      # by delegating to the existing input converter pipeline.
      class ToCoreModel
        class << self
          # Transform an HTML model (Leptris node) to CoreModel
          #
          # @param model [Leptris::XML::Document, Leptris::XML::Node, Ceradoc::CoreModel::Base]
          #   HTML input model to transform
          # @return [Ceradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Ceradoc::CoreModel::Base
              model
            when Leptris::XML::Document, Leptris::XML::Node
              ::Ceradoc::Html::HtmlConverter.to_core_model(model)
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end
        end

        def transform(model) = self.class.transform(model)
      end
    end
  end
end
