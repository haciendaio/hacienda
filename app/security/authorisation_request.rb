module Hacienda
  module Security

    class AuthorisationRequest

      attr_reader :client_id, :nonce, :timestamp, :authorisation, :body

      def initialize(body_stream, headers)
        @client_id = headers['HTTP_CLIENTID']
        @nonce = headers['HTTP_NONCE']
        @timestamp = headers['HTTP_TIMESTAMP']
        @authorisation = headers['HTTP_AUTHORIZATION']
        @body = body_stream.read
        body_stream.rewind
      end

      def has_missing_headers?
        !(@client_id && @authorisation && @nonce && @timestamp)
      end

      def authorization_hash
        @authorisation.split[1]
      end

    end
  end
end