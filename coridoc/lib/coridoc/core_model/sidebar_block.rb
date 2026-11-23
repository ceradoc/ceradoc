# frozen_string_literal: true

module Coridoc
  module CoreModel
    # Sidebar block — a delimited block for sidebars
    class SidebarBlock < Block
      def self.semantic_type
        :sidebar
      end
    end
  end
end
