require 'rspec/core/rake_task'

desc 'Run specs'
task :spec => [ :clean, 'spec:unit', 'spec:integration', 'spec:functional', 'spec:end_to_end']

desc 'Run specs without end to end tests'
task :spec_without_end_to_end => [ :clean, 'spec:unit', 'spec:integration', 'spec:functional']

namespace :spec do

  desc 'Run controller functional tests'
  RSpec::Core::RakeTask.new(:functional) do |t|
    t.pattern = 'spec/functional/*_spec.rb'
  end

  desc 'Run integration tests'
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end

  desc 'Run unit'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  desc 'Run data integrity tests [pass environment names to test specific content repos]'
  RSpec::Core::RakeTask.new(:data_integrity) do |t,args|
    envs = args.extras
    unless envs.empty?
      ENV['DATA_INTEGRITY_SPEC_ENVIRONMENTS'] = envs.join(',')
    end
    t.pattern = 'spec/data_integrity/**/*_spec.rb'
  end

  desc 'run end to end tests'
  RSpec::Core::RakeTask.new(:end_to_end, :server_name) do |t, args|
    ENV['TEST_HOST'] = args[:server_name] unless args[:server_name].nil?
    t.pattern = 'spec/end_to_end/*_spec.rb'
  end

end

