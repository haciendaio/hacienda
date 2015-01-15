require 'rack/test'

module Hacienda
    module TestClient

      def client
        RackClient.new
      end

      class RackClient

        class RackTest
          include Rack::Test::Methods
        end

        def initialize
          @rack_test = RackTest.new
        end

        def get(path, headers = {})
          headers.each do |header_name, header_value|
            @rack_test.header(header_name, header_value)
          end
          @rack_test.get path
          @rack_test.last_response
        end

        def post(url, params, additional_headers = {})
          env = rack_environment(additional_headers)
          @rack_test.post url, params, env
          @rack_test.last_response
        end

        def put(url, params, additional_headers = {})
          env = rack_environment(additional_headers)
          @rack_test.put url, params, env
          @rack_test.last_response
        end

        def upload(url, path, type, headers)
          @rack_test.put url, { 'file' => Rack::Test::UploadedFile.new(path, type) }, headers
        end

        def delete(url, additional_headers)
          env = rack_environment(additional_headers)
          @rack_test.delete url, {}, env
        end
        private

        def rack_environment(additional_headers)
          env = {}
          additional_headers.each_pair { |name, value|
            env["HTTP_#{name.upcase.gsub('-', '_')}"] = value
          }
          env
        end

      end
    end
  end
