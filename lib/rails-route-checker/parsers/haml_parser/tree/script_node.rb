module RailsRouteChecker::Parsers::HamlParser::Tree
  class ScriptNode < Node
    def script
      @value[:text]
    end
  end
end
