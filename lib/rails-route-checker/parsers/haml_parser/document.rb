# frozen_string_literal: true

module RailsRouteChecker
  module Parsers
    module HamlParser
      class Document
        attr_reader :tree, :source, :source_lines

        def initialize(source)
          @source = source.force_encoding(Encoding::UTF_8)
          @source_lines = @source.split(/\r\n|\r|\n/)

          version = Gem::Version.new(Haml::VERSION).approximate_recommendation

          original_tree = case version
                          when '~> 4.0', '~> 4.1'
                            options = Haml::Options.new
                            Haml::Parser.new(@source, options).parse
                          when '~> 5.0', '~> 5.1', '~> 5.2'
                            options = Haml::Options.new
                            Haml::Parser.new(options).call(@source)
                          when '~> 6.0', '~> 6.1', '~> 6.2'
                            Haml::Parser.new({}).call(@source)
                          else
                            raise "Cannot handle Haml version: #{version}"
                          end

          @tree = process_tree(original_tree)
        end

        private

        def process_tree(original_tree)
          original_tree.children.pop if Gem::Requirement.new('~> 4.0.0').satisfied_by?(Gem.loaded_specs['haml'].version)

          convert_tree(original_tree)
        end

        def convert_tree(haml_node, parent = nil)
          node_class_name = "#{haml_node.type.to_s.split(/[-_ ]/).collect(&:capitalize).join}Node"
          node_class_name = 'Node' unless RailsRouteChecker::Parsers::HamlParser::Tree.const_defined?(node_class_name)

          new_node = RailsRouteChecker::Parsers::HamlParser::Tree.const_get(node_class_name).new(self, haml_node)
          new_node.parent = parent

          new_node.children = haml_node.children.map do |child|
            convert_tree(child, new_node)
          end

          new_node
        end
      end
    end
  end
end
