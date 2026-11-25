# frozen_string_literal: true

module Ceradoc
  module Reference
    module Resolver
      # Protocol base. Concrete resolvers implement +#resolve(edge)+
      # and return a Result sum type instance — never +nil+.
      class Base
        def resolve(edge)
          raise NotImplementedError
        end
      end
    end
  end
end
