require_relative '../../rake/tasks/run'
require_relative '../../rake/tasks/bootstrap'

def set_environment(environment)
  ENV['RACK_ENV'] = environment.to_s
end

def env
  (ENV['RACK_ENV'] || 'development').to_sym
end
