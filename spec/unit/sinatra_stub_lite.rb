require 'rspec'
require_relative '../../spec/fake_settings'

module Hacienda
  module Test

    class SinatraStubLite
      include FakeSettings

      attr_reader :request, :redirected_to, :settings

      def initialize(settings = fake_settings)
        @request = StubRequest.new
        @request.url = 'www.thoughtworks.com'
        @settings = settings
      end

      def with_url url
        @request.url = url
      end

      def slim *rest
      end

      def halt code
        @halt_code = code
      end

      def redirect(redirected_to, code)
        @redirected_to = redirected_to
        @status_code = code
      end

      def halted_with
        @halt_code
      end

      def status code
        @status_code = code
      end

      def status_value
        @status_code
      end

    end

    class StubRequest
      attr_accessor :url
    end
  end
end
