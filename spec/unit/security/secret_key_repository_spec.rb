require_relative '../unit_helper'
require_relative '../../../app/security/key_repository'
require_relative '../../../spec/fake_settings'

include Hacienda::Test::FakeSettings

module Hacienda
  module Security
    module Test

      describe 'Key Repository' do
        it 'should use the key file to look up client ids' do
          fake_yaml = double('Yaml', load_file: {'key' => 'value'})

          key_repository = KeyRepository.new(fake_settings_with(:key_file, '/fake/path/test_key_file.yml'), fake_yaml)

          fake_yaml.should have_received(:load_file).with('/fake/path/test_key_file.yml')
          key_repository.key_for('key').should eq 'value'
        end
      end
    end

  end
end
