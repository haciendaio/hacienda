require File.join(File.dirname(__FILE__), 'lib', 'hacienda_service')

config_file = File.expand_path('config/config.yml', File.dirname(__FILE__))

Hacienda::HaciendaService.load_config_file config_file

run Hacienda::HaciendaService
