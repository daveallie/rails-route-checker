# frozen_string_literal: true

module RailsRouteChecker
  module Parsers
    module HamlParser
      module Tree
        class RootNode < Node
          def file
            @document.file
          end
        end
      end
    end
  end
end
