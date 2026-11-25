# frozen_string_literal: true

module Ceradoc
  module AsciiDoc
    module Model
      module Inline
        class Base < Ceradoc::AsciiDoc::Model::Base
          def inline?
            true
          end
        end
      end
    end
  end
end
