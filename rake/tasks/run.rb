desc 'Run using default runner'
task run: ['run:rerun']

namespace :run do

  desc 'Run rackup'
  task :rackup do
    set_environment env
    sh 'rackup config.ru'
  end

  desc 'Run rerun'
  task :rerun do
    set_environment env
    sh 'rerun -- rackup --port 9696 config.ru'
  end

end