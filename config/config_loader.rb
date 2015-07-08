require 'pathname'

module Hacienda
  class ConfigLoader

    def initialize(context, config_module)
      @context = context
      @context.register config_module
    end

    def load_config_file(config_file)
      @context.set :root, app_path

      #Don't delete the line below as Sinatra Config really really needs the full list of environments
      #Reading the list of environments directly from the config file
      @context.set :environments, environments_read_from_config_file(config_file)

      @context.config_file config_file
    end

    private

    def environments_read_from_config_file(config_file)
      YAML.load(IO.read(config_file)).keys
    end

    def app_path
      Pathname.new(File.dirname(__FILE__)).parent.join('app').to_s
    end
  end
end
