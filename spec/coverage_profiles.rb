require 'simplecov'

SimpleCov.command_name :content_service

SimpleCov.profiles.define 'base' do
  root = Pathname.new(File.dirname(__FILE__)).parent.to_s
  puts "root: #{root}"
  SimpleCov.root(root)
  SimpleCov.coverage_dir('build/coverage')

  add_filter { |sourcefile|
    name = sourcefile.filename
    ! name.include?('app') && ! name.include?('config')
  }
end

SimpleCov.profiles.define 'general' do
  load_profile 'base'
  SimpleCov.minimum_coverage 60
  puts "\nUsing coverage profile 'general' with minimum coverage of 60%\n"
end

SimpleCov.profiles.define 'integration' do
  load_profile 'base'
  SimpleCov.minimum_coverage 50
  puts "\nUsing coverage profile 'integration' with minimum coverage of 50%\n"
end

SimpleCov.profiles.define 'end_to_end' do
  load_profile 'base'
  SimpleCov.minimum_coverage 40
  puts "\nUsing coverage profile 'end_to_end' with minimum coverage of 40%\n"
end