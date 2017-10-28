module RailsRouteChecker
  class LoadedApp
    def initialize
      @app = suppress_output do
        app_base_path = Dir.pwd
        require_relative "#{app_base_path}/config/boot"
        require_relative "#{Dir.pwd}/config/environment"

        a = Rails.application
        a.eager_load!
        attempt_to_load_default_controllers
        a.reload_routes!
        Rails::Engine.subclasses.each(&:eager_load!)

        a
      end
    end

    def routes
      return @routes if defined?(@routes)

      @routes = app.routes.routes.reject do |r|
        reject_route?(r)
      end.uniq

      return @routes unless @app.config.respond_to?(:assets)

      use_spec = defined?(ActionDispatch::Journey::Route) || defined?(Journey::Route)
      @routes.reject do |route|
        path = use_spec ? route.path.spec.to_s : route.path
        path =~ /^#{app.config.assets.prefix}/
      end
    end

    def all_route_names
      @all_route_names ||= app.routes.routes.map(&:name).compact
    end

    def controller_information
      @controller_information ||= ActionController::Base.descendants.map do |controller|
        next if controller.controller_path.start_with?('rails/')

        instance_methods = (controller.instance_methods.map(&:to_s) + controller.private_instance_methods.map(&:to_s))

        [
          controller.controller_path,
          {
            helpers: controller.helpers.methods.map(&:to_s),
            actions: controller.action_methods.to_a,
            instance_methods: instance_methods.compact.uniq
          }
        ]
      end.compact.to_h
    end

    private

    attr_reader :app

    def suppress_output
      begin
        original_stderr = $stderr.clone
        original_stdout = $stdout.clone
        $stderr.reopen(File.new('/dev/null', 'w'))
        $stdout.reopen(File.new('/dev/null', 'w'))
        retval = yield
      rescue Exception => e # rubocop:disable Lint/RescueException
        $stdout.reopen(original_stdout)
        $stderr.reopen(original_stderr)
        raise e
      ensure
        $stdout.reopen(original_stdout)
        $stderr.reopen(original_stderr)
      end
      retval
    end

    def attempt_to_load_default_controllers
      # rubocop:disable Lint/HandleExceptions
      begin
        ::Rails::InfoController
      rescue NameError # ignored
      end
      begin
        ::Rails::WelcomeController
      rescue NameError # ignored
      end
      begin
        ::Rails::MailersController
      rescue NameError # ignored
      end
      # rubocop:enable Lint/HandleExceptions
    end

    def reject_route?(route)
      return true if route.name.nil? && route.requirements.blank?
      return true if route.app.is_a?(ActionDispatch::Routing::Mapper::Constraints) &&
                     route.app.app.respond_to?(:call)
      return true if route.app.is_a?(ActionDispatch::Routing::Redirect)

      controller = route.requirements[:controller]
      action = route.requirements[:action]
      return true unless controller && action
      return true if controller.start_with?('rails/')
      false
    end
  end
end
