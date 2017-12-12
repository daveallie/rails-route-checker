require_relative 'haml_parser/document'
require_relative 'haml_parser/tree/node'
require_relative 'haml_parser/tree/filter_node'
require_relative 'haml_parser/tree/root_node'
require_relative 'haml_parser/tree/script_node'
require_relative 'haml_parser/tree/silent_script_node'
require_relative 'haml_parser/tree/tag_node'
require_relative 'haml_parser/ruby_extractor'

module RailsRouteChecker
  module Parsers
    module HamlParser
      class << self
        def run(filename, **opts)
          file_source = opts[:source] || File.read(filename)

          document = RailsRouteChecker::Parsers::HamlParser::Document.new(file_source)
          extracted_ruby = RailsRouteChecker::Parsers::HamlParser::RubyExtractor.extract(document)

          opts[:source] = extracted_ruby.source
          opts[:source_map] = extracted_ruby.source_map

          RailsRouteChecker::Parsers::RubyParser.run(filename, **opts)
        end
      end
    end
  end
end
