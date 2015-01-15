require 'sinatra/config_file'

require_relative '../config/config_loader'
require_relative '../app/routes/content_service_routes'

module Hacienda
  class HaciendaService < Sinatra::Base
     def self.load_config_file file
       ConfigLoader.new(self, Sinatra::ConfigFile).load_config_file file
     end
  end

end
