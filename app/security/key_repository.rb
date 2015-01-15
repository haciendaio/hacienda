require 'yaml'
require_relative '../../app/utilities/log'

module Hacienda
  module Security
    class KeyRepository

      def initialize(settings, yaml = YAML)
        @logger = Log.new(settings)
        @secrets = yaml.load_file(settings.key_file)
      end

      def key_for(client_id)
        @secrets[client_id]
      end

    end
  end
end
