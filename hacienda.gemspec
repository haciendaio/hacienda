require 'date'
patch_number = ENV['GO_PIPELINE_COUNTER'] || 0

Gem::Specification.new do |s|
  s.name        = 'hacienda'
  s.version     = "0.1.25.#{patch_number}"
  s.date        = Date.today.to_s
  s.summary     = 'Hacienda is a RESTful service to manage content'
  s.description = 'Hacienda is a RESTful service to manage content'
  s.authors     = ['Thougthworks']
  s.email       = 'www-devs@thoughtworks.com'
  s.files       = %w(lib/hacienda_service.rb lib/hacienda/tasks.rb lib/hacienda/test_support.rb config/config_loader.rb) + Dir['app/**/*.rb'] +  Dir['spec/**/*.rb'] + Dir['rake/tasks/*']
  s.homepage    =
      'http://rubygems.org/gems/hola'
  s.license       = 'AGPL'

  s.add_dependency 'sinatra', '1.4.3'
  s.add_dependency 'sinatra-contrib', '1.4.1'
  s.add_dependency 'json', '1.8.2'
  s.add_dependency 'multi_json'
  s.add_dependency 'octokit', '2.5.1'
  s.add_dependency 'rugged', '~> 0.21.0'
  s.add_dependency 'unicorn', '~> 4.8.3'

  s.add_development_dependency 'thin'
  s.add_development_dependency 'rerun'
  s.add_development_dependency 'rake', '10.1.0'
  s.add_development_dependency 'rspec', '2.14.1'
  s.add_development_dependency 'faraday', '0.8.7'
  s.add_development_dependency 'rack-test', '0.6.2'
  s.add_development_dependency 'simplecov',  '~> 0.9.0'
end