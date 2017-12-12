module RailsRouteChecker::Parsers::HamlParser::Tree
  class RootNode < Node
    def file
      @document.file
    end
  end
end
