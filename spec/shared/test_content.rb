require_relative 'navigation'

module Hacienda
  module Test
    class TestContent

      class ApiClient
        include Navigation
        include TestClient
      end

      include Hacienda::Test::KeyMocking

      def initialize
        @ApiClient = ApiClient.new

        client_id = SecureRandom.hex(32).upcase
        client_secret = SecureRandom.hex(32).upcase

        @authorised_client_data = {
            nonce: '84024B89D',
            client_id: client_id,
            timestamp: Time.now.to_i.to_s,
            secret: client_secret
        }

        add_credentials_to_test_keys client_id, client_secret
      end

      def add(content, options = {})
        content.merge!(locale: options[:in]) if options[:in]
        @ApiClient.create_item(content[:type], content, content[:locale], @authorised_client_data)
      end

      def update(content, options = {})
        content.merge!(locale: options[:in]) if options[:in]
        @ApiClient.update_item(content[:type], content, content[:locale], @authorised_client_data)
      end

      def publish(content, options = {})
        content.merge!(locale: options[:in]) if options[:in]
        version = (get_draft of: content, in: options[:in])[:version]
        @ApiClient.publish_single_content_item(content[:type], content[:id], @authorised_client_data, version, content[:locale])
      end

      def get_draft(options)
        translation_of = options[:of]
        translated_to = options[:in]
        @ApiClient.get_draft_translated_item_by_id translation_of[:type], translation_of[:id], translated_to
      end

      def get_public(options)
        translation_of = options[:of]
        translated_to = options[:in]
        @ApiClient.get_public_translated_item_by_id translation_of[:type], translation_of[:id], translated_to
      end

      def delete(content)
        @ApiClient.delete_item(content[:type],content[:id], @authorised_client_data)
      end
    end

  end
end