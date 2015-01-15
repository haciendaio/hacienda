require 'forwardable'
require 'faraday'

module Hacienda
  module Test
    module TestClient

      def connecting_to(hostname, port, headers={})
        @client = FaradayClient.new(hostname, port, headers)
      end

      def client
        @client
      end

      class FaradayClient

        def initialize(hostname, port, headers)
          @connection = Faraday.new("http://#{hostname}:#{port}")
          @headers = headers
        end

        def get(path, headers = {})
          headers.each do |header_name, header_value|
            @headers[header_name] = header_value
          end
          @connection.get(path) do |req|
            req.headers = @headers
          end
        end

        def put(path, params, additional_headers = {})
          send_request(:put, path, params, additional_headers)
        end

        def delete(path, additional_headers = {})
          send_request(:delete, path, additional_headers)
        end

        def post(path, params, additional_headers = {})
          send_request(:post, path, params, additional_headers)
        end

        class Response
          extend Forwardable

          def initialize(faraday_response)
            @response = faraday_response
          end

          def_delegators :@response, :body, :status, :content, :headers

        end

        private

        def send_request(request_verb, path, params, additional_headers = {})
          Response.new(
              faraday_response = @connection.send(request_verb, path, params) do |req|
                req.headers = additional_headers.merge!(@headers)
              end
          )
        end

      end

    end

  end
end


