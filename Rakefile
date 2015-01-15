require 'rake/clean'

def env
  (ENV['RACK_ENV'] || 'development').to_sym
end

def set_environment(environment)
  ENV['RACK_ENV'] = environment.to_s
end

def load_task(name, from_dir='rake/tasks')
  load(File.join(File.dirname(__FILE__), from_dir, "#{name}.rb"))
end

def revision
  revision = ENV['GO_PIPELINE_LABEL'] || 'unversioned'
end

def load_extra_rake_tasks
  %w{spec bootstrap run}.each do |task|
    load_task task
  end
end

time_before = Time.now.utc

puts "Running on Environment: #{env}"

Bundler.require(:default, env)

if env != :production
  load_extra_rake_tasks
end

task :default => :spec

directory 'target'

task :git_archive do
  sh "git archive master --output target/content_service_#{revision}.tar"
end

task :git_end_to_end_archive do
  sh 'git archive master --output target/content_service_end_to_end_tests.tar'
end

def linux_specific_options
  linux = RUBY_PLATFORM.include?('linux')
  options = linux ? '--hard-dereference -h' : ''
  options
end

desc 'Package Content service'
task :package => ['target', :git_archive] do
  %w(bin .bundle).each do |path|
    sh "tar -uf target/content_service_#{revision}.tar #{path}"
  end
  sh "tar #{linux_specific_options} -uf target/content_service_#{revision}.tar vendor"
  sh "gzip target/content_service_#{revision}.tar"
end

desc 'Package for end_to_end tests'
task :package_for_end_to_end_tests  => ['target', :git_end_to_end_archive] do
    %w(bin .bundle).each do |path|
      sh "tar #{linux_specific_options} -uf target/content_service_end_to_end_tests.tar #{path}"
    end
    sh "tar #{linux_specific_options} -uf target/content_service_end_to_end_tests.tar vendor"
    sh 'gzip target/content_service_end_to_end_tests.tar'
  end



puts '------------------------------------------'
puts 'Time used for everything after bundler require within Rakefile: ' + (Time.now.utc-time_before).to_s
puts '------------------------------------------'

