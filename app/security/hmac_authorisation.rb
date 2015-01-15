require_relative '../../app/security/key_repository'
require_relative '../../app/utilities/log'
require_relative 'authorisation_request'
require_relative 'cryptography'

module Hacienda
  module Security

    class HMACAuthorisation

      def initialize(settings, time = Time, key_repository = KeyRepository.new(settings), cryptography = Cryptography.new)
        @key_repository = key_repository
        @cryptography = cryptography
        @logger = Log.new(settings)
        @time = time
      end
      
      def authorised?(request)
        authorisation_request = AuthorisationRequest.new(request.body, request.env)

        return false if request_has_missing_headers(authorisation_request) or client_not_recognised(authorisation_request)

        return false if request_stale? authorisation_request

        expected_hash = @cryptography.generate_authorisation_data(authorisation_request.body, @key_repository.key_for(authorisation_request.client_id), authorisation_request.nonce, authorisation_request.timestamp)[:hash]

        hashes_match(authorisation_request.authorization_hash, expected_hash)
      end

      private

      ONE_MINUTE_IN_SECONDS = 60

      def request_stale?(authorisation_request)
        authorisation_request.timestamp.to_i < (@time.now.to_i - ONE_MINUTE_IN_SECONDS)
      end

      def client_not_recognised(authorisation_request)
        key_not_recognised = !@key_repository.key_for(authorisation_request.client_id)
        @logger.error("Authorisation denied due to unrecognised client id: #{authorisation_request.client_id}") if key_not_recognised
        key_not_recognised
      end

      def hashes_match(candidate_hash, expected_hash)
        hashes_match = candidate_hash == expected_hash
        @logger.error('Authorisation denied due to hashes not matching.') unless hashes_match
        hashes_match
      end

      def request_has_missing_headers(authorisation_request)
        @logger.error('Authorisation denied due to missing mandatory headers') if authorisation_request.has_missing_headers?
        authorisation_request.has_missing_headers?
      end
    end

  end
end
