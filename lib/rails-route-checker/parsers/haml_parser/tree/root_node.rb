module RailsRouteChecker::Parsers::HamlParser::Tree
  class RootNode < Node
    def file
      @document.file
    end

    def node_for_line(line)
      find(-> { RailsRouteChecker::Parsers::HamlParser::Tree::NullNode.new }) { |node| node.line_numbers.cover?(line) }
    end
  end
end
