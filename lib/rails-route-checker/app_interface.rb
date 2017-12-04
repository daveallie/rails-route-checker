module RailsRouteChecker
  class AppInterface
    def initialize(**opts)
      @options = { ignored_controllers: [], ignored_paths: [], ignored_path_whitelist: {} }.merge(opts)
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
        next unless controller # controller will be nil if it's an ignored controller

        items = []

        deep_iterator(Ripper.sexp(File.read(filename))) do |item, extra_data|
          scope = extra_data[:scope]
          next unless %i[vcall fcall].include?(scope[-2])
          next unless scope[-1] == :@ident
          next unless item.end_with?('_path', '_url')
          next if match_in_whitelist?(filename, item)
          next if match_defined_in_ruby?(controller, item)
          line = extra_data[:position][0]
          items << { file: filename, line: line, method: item }
        end

        items
      end.flatten
    end

    def deep_iterator(list, current_scope = [], current_line_num = [], &block)
      if list.is_a?(Array)
        if list[0].is_a?(Symbol)
          current_scope << list[0]

          if list[-1].is_a?(Array) && list[-1].length == 2 && list[-1].all? { |item| item.is_a?(Fixnum) }
            current_line_num = list[-1]
            list = list[0..-2]
          end

          list[1..-1].each do |item|
            deep_iterator(item, current_scope, current_line_num, &block)
          end
          current_scope.pop
        else
          list.each do |item|
            deep_iterator(item, current_scope, current_line_num, &block)
          end
        end
      elsif !list.nil?
        yield(list, { scope: current_scope, position: current_line_num })
      end
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
