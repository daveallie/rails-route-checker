# frozen_string_literal: true

module RailsRouteChecker
  class Runner
    def initialize(**opts)
      @options = { ignored_controllers: [], ignored_paths: [], ignored_path_whitelist: {} }
      @options.merge!(RailsRouteChecker::ConfigFile.new(opts[:config_file]).config) if opts[:config_file]
      @options.merge!(opts)
    end

    def issues
      @issues ||= {
        missing_actions: app_interface.routes_without_actions,
        missing_routes: app_interface.undefined_path_method_calls
      }
    end

    def issues?
      issues.values.flatten(1).count.positive?
    end

    def output
      output_lines = []
      output_lines += missing_actions_output if issues[:missing_actions].any?
      if issues[:missing_routes].any?
        output_lines << "\n" if output_lines.any?
        output_lines += missing_routes_output
      end
      output_lines = ['All good in the hood'] if output_lines.empty?
      output_lines.join("\n")
    end

    private

    def app_interface
      @app_interface ||= RailsRouteChecker::AppInterface.new(@options)
    end

    def missing_actions_output
      [
        "The following #{issues[:missing_actions].count} routes are defined, " \
        'but have no corresponding controller action.',
        'If you have recently added a route to routes.rb, make sure a matching action exists in the controller.',
        'If you have recently removed a controller action, also remove the route in routes.rb.',
        *issues[:missing_actions].map { |r| " - #{r[:controller]}##{r[:action]}" }
      ]
    end

    def missing_routes_output
      [
        "The following #{issues[:missing_routes].count} url and path methods don't correspond to any route.",
        *issues[:missing_routes].map { |line| " - #{line[:file]}:#{line[:line]} - call to #{line[:method]}" }
      ]
    end
  end
end
