require 'rspec'

require_relative 'faraday_client'
require_relative '../../shared/hacienda_runner'
require_relative '../../../app/github/github'
require_relative '../../../app/github/github_client'
require_relative '../../../app/exceptions/not_found_exception'
require_relative '../../coverage_profiles'

SimpleCov.start 'end_to_end'

RSpec.configure do |config|
  config.include Hacienda::Test::TestClient
end

def run_local_service
  puts 'Using localhost'
  hostname = 'localhost'
  port = '9696'
  connecting_to hostname, port
  Hacienda::Test::HaciendaRunner.new(hostname, port).start
end

def upsert_content(github, file_content, item_path)
  github.create_content("#{item_path} updated for test", item_path => file_content)
end
