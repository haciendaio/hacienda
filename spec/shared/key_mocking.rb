require 'fileutils'

module Hacienda
  module Test
    module KeyMocking
      def add_credentials_to_test_keys(client_id, client_secret, fake_config_loader = FakeConfigLoader.new)
        key_file = fake_config_loader.load_config('test').key_file

        dirname = File.dirname(key_file)

        unless File.directory?(dirname)
          FileUtils.mkdir_p dirname
        end

        File.open(key_file, 'w+') do |file|
          file.puts "#{client_id}: #{client_secret}"
        end
      end

    end
  end
end
