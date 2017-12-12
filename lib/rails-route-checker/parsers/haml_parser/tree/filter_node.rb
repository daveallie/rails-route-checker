module RailsRouteChecker::Parsers::HamlParser::Tree
  class FilterNode < Node
    def filter_type
      @value[:name]
    end
  end
end
