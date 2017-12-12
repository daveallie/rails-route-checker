module RailsRouteChecker
  module Parsers
    module HamlParser
      module Tree
        class ScriptNode < Node
          def script
            @value[:text]
          end
        end
      end
    end
  end
end
