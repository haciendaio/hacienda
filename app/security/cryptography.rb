require 'openssl'

module Hacienda
  module Security
    class Cryptography

      DIGEST = OpenSSL::Digest.new('sha512')

      def generate_authorisation_data(message, secret, nonce=generate_nonce, timestamp=generate_timestamp)
        string_to_hash = "#{message}|#{nonce}|#{timestamp}"
        generated_hash = OpenSSL::HMAC.digest(DIGEST, secret, string_to_hash).unpack('H*').first.upcase
        {
            hash: generated_hash,
            timestamp: timestamp,
            nonce: nonce
        }
      end

      private

      def generate_nonce
        (0...8).map { (65+rand(26)).chr }.join
      end

      def generate_timestamp
        Time.now.to_i
      end

    end
  end
end
