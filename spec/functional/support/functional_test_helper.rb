require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)

require_relative '../../spec_helper'

require_relative '../../../config/config_loader'
require_relative '../../../lib/hacienda_service'

require_relative 'rack_client'


class Hacienda::HaciendaService < Sinatra::Base
  set :environment, 'test'
end

config_path = Pathname.new(File.dirname(__FILE__)).join('../../../config/config.yml').to_s
raise Exception.new('There is no config file. Please run the bootstrap:config task to setup one') unless File.exists? config_path

Hacienda::HaciendaService.load_config_file config_path

def app
  Hacienda::HaciendaService
end

RSpec.configure do |config|
  config.include Hacienda::TestClient
end

