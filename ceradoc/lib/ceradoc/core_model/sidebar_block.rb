# frozen_string_literal: true

module Ceradoc
  module CoreModel
    # Sidebar block — a delimited block for sidebars
    class SidebarBlock < Block
      def self.semantic_type
        :sidebar
      end
    end
  end
end
