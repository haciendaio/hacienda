require File.join(File.dirname(__FILE__), 'lib', 'hacienda_service')

config_file = Pathname.new(File.dirname(__FILE__)).join('config/config.yml').to_s

Hacienda::HaciendaService.load_config_file config_file

run Hacienda::HaciendaService