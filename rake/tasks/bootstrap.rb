require 'yaml'
require 'securerandom'
require_relative '../../config/config_loader'
require_relative '../../app/github/github_settings'

require 'sinatra/config_file'
require 'octokit'
require 'fileutils'

include Hacienda::GithubSettings

def load_bootstrap_config
  YAML::load_file('config/config.yml')
end

def settings
  Sinatra::Application.settings
end

def clone_repo(local_dir, repo_full_name, token, safe = true)
  if safe and Dir.exists? local_dir
      puts "The folder specified in the content_directory_path: #{local_dir} already exists, please choose another folder to clone the content repo before going further"
      exit 1
  end

  if !safe
    puts "I am removing the #{local_dir} and all its contents!"
    system("rm -rf #{local_dir}")
  end

  puts 'Cloning master repo...'
  system("git clone https://#{token}@github.com/#{repo_full_name}.git #{local_dir}")
  puts 'Finished cloning master repo...'
end

def create_repo(github_client, repo_name, repo_creation_options)
  puts 'creating repo...'
  repo_creation_options.merge! auto_init: true
  github_client.create_repository(repo_name, repo_creation_options)
  puts 'waiting for the repo creation...'
  sleep 10
end

def bootstrap_repo(token = ENV['GITHUB_OAUTH_TOKEN'], safe = true)

  repo_name = settings.content_repo
  local_dir = settings.content_directory_path

  repo_creation_options = is_github_organization_defined?(settings) ? { organization: settings.github_organization } : {}

  github_client = Octokit::Client.new(:access_token => token)

  repo_full_name = repo_qualified_name(settings)

  repo_exists = github_client.repository?(repo_full_name)
  create_repo(github_client, repo_name, repo_creation_options) unless repo_exists
  clone_repo(local_dir, repo_full_name, token, safe)
end

def add_webhook_for(repo_full_name, dns_entry)
  endpoint = "#{dns_entry}/content-updated"

  config = {
      url: endpoint,
      content_type: 'json'
  }

  options = {
      events: ['push'],
      active: true
  }

  token = ENV['GITHUB_OAUTH_TOKEN']
  github_client = Octokit::Client.new(:access_token => token)

  github_client.create_hook(repo_full_name, 'web', config, options)
end

def use_settings_for_env env
  Sinatra::Application.set :environment, env
  config_file_path = File.expand_path 'config/config.yml'
  Hacienda::ConfigLoader.new(Sinatra::Application, Sinatra::ConfigFile).load_config_file(config_file_path)
end

def bootstrap_for_env env
  use_settings_for_env(env)
  bootstrap_repo
end

task bootstrap: %w(bootstrap:repo)

namespace :bootstrap do

  desc 'Creating a config from the config example - without the production repo'
  task :config do
    puts 'You are creating a new config file'

    puts 'What is the Github username:'
    github_user = STDIN.gets.chomp

    github_token = ENV['GITHUB_OAUTH_TOKEN']

    puts 'What is the Github test repo (it will create if not existent):'
    github_test_repo = STDIN.gets.chomp

    puts 'What is the Github development repo (it will create if not existent):'
    github_development_repo = STDIN.gets.chomp

    config_content = IO.read('config/config.example.yml')

    config_content.gsub!('<Github Test Repo>', github_test_repo)
    config_content.gsub!('<Github User>', github_user)
    config_content.gsub!('<Github Development Repo>', github_development_repo)

    File.open('config/config.yml','w+') do |file|
      file.puts config_content
    end

    use_settings_for_env :test
    bootstrap_repo(github_token)

    use_settings_for_env :development
    bootstrap_repo(github_token)
  end

  desc 'Creating a config from the config example - without the production repo'
  task :config_unattended, :github_user, :github_test_repo do |_, args|

    puts 'Creating a new config file'

    github_user = args[:github_user]
    puts "Github username: #{github_user}"

    github_token = ENV['GITHUB_OAUTH_TOKEN']

    github_test_repo = args[:github_test_repo]
    github_development_repo = args[:github_test_repo]
    puts "Github test repo #{github_test_repo}"

    config_content = IO.read('config/config.example.yml')

    config_content.gsub!('<Github Test Repo>', github_test_repo)
    config_content.gsub!('<Github User>', github_user)
    config_content.gsub!('<Github Development Repo>', github_development_repo)

    File.open('config/config.yml','w+') do |file|
      file.puts config_content
    end

    use_settings_for_env :test
    bootstrap_repo(github_token, false)

    use_settings_for_env :development
    bootstrap_repo(github_token, false)
  end

  desc 'Adding webhook for a repo'
  task :webhook, :env, :dns_entry do |_, args|
    env = args[:env].to_sym
    dns_entry = args[:dns_entry]

    use_settings_for_env env

    add_webhook_for repo_qualified_name(settings), dns_entry
  end

  desc 'Setting up the repo for use'
  task :repo, :env, :dns_entry do |_, args|
    dns_entry = args[:dns_entry]

    use_settings_for_env args[:env].to_sym

    bootstrap_repo

    add_webhook_for(repo_qualified_name(settings), dns_entry) if dns_entry
  end

  desc 'Setting up the test repo'
  task :test_repo do
    bootstrap_for_env :test
  end

  desc 'Setting up the development repo'
  task :dev_repo do
    bootstrap_for_env :development
  end

  desc 'Generating keys for clients'
  task :generate_id_and_secret do
    consumer_id = SecureRandom.hex(32).upcase
    consumer_secret = SecureRandom.hex(32).upcase

    puts 'Here be dragons!'
    puts 'You are creating a new client id and client secret. This is just generating them. You need to add them to your client and content service'
    puts "Client Id:     #{consumer_id}"
    puts "Client Secret: #{consumer_secret}"
  end

  desc 'Add consumer to the list of consumers accepted'
  task :add_consumer_with_credentials, :env, :consumer_id, :consumer_secret do |_, args|
    env = args[:env].to_sym
    use_settings_for_env env

    consumer_id = args[:consumer_id]
    consumer_secret = args[:consumer_secret]

    path_to_keys = settings.key_file

    path_to_keys_dir_name = path_to_keys.split('/')[0...-1].join('/')

    unless File.directory?(path_to_keys_dir_name)
      FileUtils.mkdir_p(path_to_keys_dir_name)
    end

    File.open(path_to_keys, 'a+') do |file|
      file.puts "#{consumer_id}: #{consumer_secret}"
    end

    puts 'You have just added a new consumer.'
  end

end
