# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      module Inline
        class Base < Coridoc::AsciiDoc::Model::Base
          def inline?
            true
          end
        end
      end
    end
  end
end
