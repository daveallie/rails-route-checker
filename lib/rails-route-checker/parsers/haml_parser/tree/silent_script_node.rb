module RailsRouteChecker::Parsers::HamlParser::Tree
  class SilentScriptNode < Node
    def script
      @value[:text]
    end
  end
end
