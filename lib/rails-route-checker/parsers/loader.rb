module RailsRouteChecker
  module Parsers
    module Loader
      class << self
        def load_parser(type)
          case type
          when :ruby
            load_basic_parser(:ruby)
          when :erb
            load_basic_parser(:ruby)
            load_basic_parser(:erb)
          when :haml
            if haml_available?
              load_basic_parser(:ruby)
              load_haml_parser
            end
          else
            raise "Unrecognised parser attempting to be loaded: #{type}"
          end
        end

        def haml_available?
          return @haml_available if defined?(@haml_available)

          @haml_available = gem_installed?('haml')
        end

        private

        def gem_installed?(name, version_requirement = nil)
          Gem::Dependency.new(name, version_requirement).matching_specs.any?
        end

        def load_basic_parser(parser_name)
          if_unloaded(parser_name) do
            require_relative "#{parser_name}_parser"
          end
        end

        def load_haml_parser
          if_unloaded(:haml) do
            require 'haml'
            require_relative 'haml_parser'
          end
        end

        def if_unloaded(parser)
          @loaded_parsers ||= {}
          return false if @loaded_parsers[parser]

          yield
          @loaded_parsers[parser] = true
        end
      end
    end
  end
end
