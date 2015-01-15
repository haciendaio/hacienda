require 'yaml'
require 'pathname'
require_relative '../../spec/fake_settings'

module Hacienda
  module Test

    class FakeConfigLoader
      include FakeSettings

      def initialize(config_path = Pathname.new(File.dirname(__FILE__)).parent.parent.join('config/config.yml').to_s)
        raise Exception.new('There is no config file. Please run the bootstrap:config task') unless File.exists? config_path
        @config_path = config_path
      end

      def load_config env
        fake_multiple_settings_with load_config_file[env]
      end

      def load_config_file
        YAML.load_file @config_path
      end

      def app_path
        Pathname.new(File.dirname(__FILE__)).parent.join('app').to_s
      end

    end
  end
end

