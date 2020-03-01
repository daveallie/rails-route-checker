# frozen_string_literal: true

module RailsRouteChecker
  module Parsers
    module HamlParser
      module Tree
        class FilterNode < Node
          def filter_type
            @value[:name]
          end
        end
      end
    end
  end
end
