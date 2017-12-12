module RailsRouteChecker
  module Parsers
    module HamlParser
      module Tree
        class SilentScriptNode < Node
          def script
            @value[:text]
          end
        end
      end
    end
  end
end
