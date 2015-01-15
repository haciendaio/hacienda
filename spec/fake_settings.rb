require 'rspec'
require 'rspec/mocks'
require 'ostruct'

module Hacienda
  module Test

    module FakeSettings

      def fake_settings_with_feature_toggle setting, value
        OpenStruct.new :feature_toggles => {setting => value}
      end

      def fake_settings_with_feature_toggles feature_toggles
        OpenStruct.new :feature_toggles => feature_toggles
      end

      def fake_settings_with setting, value
        OpenStruct.new setting.to_sym => value
      end

      def fake_multiple_settings_with settings
        fake_settings = OpenStruct.new settings
        fake_settings.log_path = '/tmp/fake_log_path'
        fake_settings
      end

      def fake_settings
        settings = fake_settings_with_feature_toggle('', '')
        settings.log_path = '/tmp/fake_log_path'
        settings
      end
    end
  end
end
