module RailsRouteChecker
  class AppInterface
    def initialize(**opts)
      @options = opts
    end

    def routes_without_actions
      loaded_app.routes.map do |r|
        controller = r.requirements[:controller]
        action = r.requirements[:action]

        next if options[:ignored_controllers].include?(controller)
        next if controller_information.key?(controller) && controller_information[controller][:actions].include?(action)

        {
          controller: controller,
          action: action
        }
      end.compact
    end

    def undefined_path_method_calls
      generate_undef_view_path_calls + generate_undef_controller_path_calls
    end

    private

    attr_reader :options

    def loaded_app
      @loaded_app ||= RailsRouteChecker::LoadedApp.new
    end

    def controller_information
      @controller_information ||= loaded_app.controller_information.reject do |path, _|
        options[:ignored_controllers].include?(path)
      end
    end

    def generate_undef_view_path_calls
      files = `find app -type f -iregex '.*\\.haml' -or -iregex '.*\\.erb' -or -iregex '.*\\.html'`.split("\n")
      files.map do |filename|
        controller = controller_from_view_file(filename)

        defined_variables = []

        File.read(filename).each_line.each_with_index.map do |line, line_num|
          next if line =~ /^\s*-\s*#/
          skip_first = false
          if line =~ /^\s*-/
            line_match = line.match(/^\s*-\s*([a-zA-Z0-9_]+_(?:path|url))\s*=/)
            defined_variables << line_match[1] if line_match
            skip_first = true
          end

          matches = line.scan(/(([a-zA-Z][a-zA-Z0-9_]*)_(?:path|url))[^a-z0-9_]/)
          matches.shift if skip_first
          ignores = line.scan(/(([a-zA-Z][a-zA-Z0-9_]*)_(?:path|url))(?: =|[!:])/).map(&:first)
          ignores += line.scan(/[.@:_'"]([a-zA-Z][a-zA-Z0-9_]+_(?:path|url))[^a-z0-9_]/).map(&:first)

          matches.reject! { |match| ignores.include?(match[0]) }

          matches.map do |match|
            next if match_in_whitelist?(filename, match)
            next if match_defined_in_view?(controller, defined_variables, match)
            { file: filename, line: line_num + 1, method: match[0] }
          end
        end
      end.flatten.compact
    end

    def generate_undef_controller_path_calls
      `find app/controllers -type f -iregex '.*\\.rb'`.split("\n").map do |filename|
        controller = controller_from_ruby_file(filename)

        File.read(filename).each_line.each_with_index.map do |line, line_num|
          next if line =~ /^\s*#/
          next if line =~ /^\s*def\s/

          matches = line.scan(/(([a-zA-Z][a-zA-Z0-9_]*)_(?:path|url))[^a-z0-9_]/)
          ignores = line.scan(/(([a-zA-Z][a-zA-Z0-9_]*)_(?:path|url))(?: =|[!:])/).map(&:first)
          ignores += line.scan(/[.@:_'"]([a-zA-Z][a-zA-Z0-9_]+_(?:path|url))[^a-z0-9_]/).map(&:first)

          matches.reject! { |match| ignores.include?(match[0]) }

          matches.map do |match|
            next if match_in_whitelist?(filename, match)
            next if match_defined_in_ruby?(controller, match)
            { file: filename, line: line_num + 1, method: match[0] }
          end
        end
      end.flatten.compact
    end

    def match_in_whitelist?(filename, match)
      full_match, possible_route_name = match
      return true if options[:ignored_paths].include?(possible_route_name)
      (options[:ignored_path_whitelist][filename] || []).include?(full_match)
    end

    def match_defined_in_view?(controller, defined_variables, match)
      full_match, possible_route_name = match
      return true if loaded_app.all_route_names.include?(possible_route_name)
      return true if defined_variables.include?(full_match)
      controller && controller[:helpers].include?(full_match)
    end

    def match_defined_in_ruby?(controller, match)
      full_match, possible_route_name = match
      return true if loaded_app.all_route_names.include?(possible_route_name)
      controller && controller[:instance_methods].include?(full_match)
    end

    def controller_from_view_file(filename)
      split_path = filename.split('/')
      possible_controller_path = split_path[(split_path.index('app') + 2)..-2]

      controller = nil
      while controller.nil? && possible_controller_path.any?
        if controller_information.include?(possible_controller_path.join('/'))
          controller = controller_information[possible_controller_path.join('/')]
        else
          possible_controller_path = possible_controller_path[0..-2]
        end
      end
      controller || controller_information['application']
    end

    def controller_from_ruby_file(filename)
      controller_name = (filename.match(%r{app/controllers/(.*)_controller.rb}) || [])[1] || 'application'
      controller_information[controller_name]
    end
  end
end
