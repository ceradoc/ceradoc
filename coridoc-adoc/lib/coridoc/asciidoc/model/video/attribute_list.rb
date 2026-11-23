# frozen_string_literal: true

module Coridoc
  module AsciiDoc
    module Model
      class Video < Base
        class AttributeList < Coridoc::AsciiDoc::Model::AttributeList
          extend AttributeList::Matchers
          def positional_validators
            [
              [:alt, String],
              [:width, Integer],
              [:height, Integer]
            ]
          end

          def named_validators
            {
              title: String,
              poster: String,
              width: Integer,
              height: Integer,
              start: Integer,
              end: Integer,
              theme: one('dark', 'light'),
              lang: /[a-z]{2,3}(?:-[A-Z]{2})?/,
              list: String,
              playlist: String,
              options: many(
                'autoplay',
                'loop',
                'modest',
                'nocontrols',
                'nofullscreen',
                'muted'
              )
            }
          end
        end
      end
    end
  end
end
