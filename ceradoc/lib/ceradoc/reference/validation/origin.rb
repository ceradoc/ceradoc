# frozen_string_literal: true

require 'lutaml/model'

module Ceradoc
  module Reference
    module Validation
      # Where a validated Edge was asked from: the path of the node that
      # owns the edge, from the document root down to that node.
      # +node_path+ names every hop ("DocumentElement#doc > " +
      # "SectionElement#sec-2 > LinkElement"); +node_id+ repeats the
      # edge-owning node's own id when it carries one.
      class Origin < Lutaml::Model::Serializable
        attribute :node_path, :string
        attribute :node_id, :string

        def to_s
          return node_path.to_s unless node_id

          "#{node_path} (id: #{node_id})"
        end
      end
    end
  end
end
