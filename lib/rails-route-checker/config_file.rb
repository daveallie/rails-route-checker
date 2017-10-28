module RailsRouteChecker
  class ConfigFile
    def initialize(filename)
      @filename = filename
    end

    def config
      @config ||= begin
        hash = load_yaml_file
        {
          ignored_controllers: hash['ignored_controllers'] || [],
          ignored_paths: hash['ignored_paths'] || [],
          ignored_path_whitelist: hash['ignored_path_whitelist'] || []
        }
      end
    end

    private

    attr_reader :filename

    def load_yaml_file
      require 'yaml'
      YAML.safe_load(File.read(filename))
    end
  end
end
