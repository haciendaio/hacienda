require_relative 'support/end_to_end_test_helper'

require_relative '../shared/navigation'
require_relative '../../spec/shared/key_mocking'
require_relative '../../spec/fake_settings'

module Hacienda
  module Test

    describe 'User Journey for translated content' do

      include Navigation
      include FakeSettings
      include KeyMocking

      def authorised_client_data
        {
            nonce: '84024B89D',
            client_id: @client_id,
            timestamp: Time.now.to_i.to_s,
            secret: @client_secret
        }
      end

      before :all do
        fake_settings = FakeConfigLoader.new.load_config 'test'

        @service_runner = run_local_service

        @test_github = Github.new(fake_settings, GithubClient.new(fake_settings))

        @client_id = SecureRandom.hex(32).upcase
        @client_secret = SecureRandom.hex(32).upcase

        add_credentials_to_test_keys @client_id, @client_secret
      end

      after :all do
        @service_runner.stop unless @service_runner.nil?
      end

      it 'should handle properly translated content with metadata in the context of create, publish & delete' do

        type = 'banana'
        bananarama_id = "bananarama-from-#{Time.now.to_i}"

        #creating new item in spanish (ES) - canonical version
        banana_item = {id: bananarama_id, title: 'spanish bananarama', content_body_html: '<p>It is very shiny and new</p>'}

        response = create_item(type, banana_item, 'es', authorised_client_data)

        expect(response.status).to eq 201
        expect(response.headers['Location']).to eq "banana/#{bananarama_id}/es"
        expect(response.headers['ETag']).not_to be_nil, 'The ETag with content version should be present'

        content_updated

        banana_resource = get_draft_translated_item_by_id(type, bananarama_id, 'es')
        expect(banana_resource).to include banana_item

        should_return_409_when_attempt_to_recreate_content_that_already_exists(type, banana_item, 'es')

        #request draft EN version, returns canonical as EN doesn't exist
        spanish_item = get_draft_translated_item_by_id(type, bananarama_id, 'en')
        expect(spanish_item[:title]).to eq 'spanish bananarama'

        update_item(type, {id: bananarama_id, title: 'english bananarama'}, authorised_client_data, 'en')
        content_updated

        english_item = get_draft_translated_item_by_id(type, bananarama_id, 'cn')
        expect(english_item[:title]).to eq 'english bananarama'

        publish_ES_item(bananarama_id, type)

        item = get_public_translated_item_by_id(type, bananarama_id, 'de')
        expect(item[:title]).to eq 'spanish bananarama'

        delete_EN_in_draft(bananarama_id, type)

        item = get_draft_translated_item_by_id(type, bananarama_id, 'pt')
        expect(item[:title]).to eq 'spanish bananarama'

        update_publish_and_request_PT_item(type, bananarama_id)

        delete_canonical_item_in_draft_and_public(bananarama_id, type)

        response = delete_item_with_locale(type, bananarama_id, authorised_client_data, 'cn')
        expect(response.status).to eq 404
      end

      private

      def content_updated
        expect(github_tells_service_that_content_updated.body).to eq 'content updated'
      end

      def should_return_409_when_attempt_to_recreate_content_that_already_exists(type, banana_item, locale)
        response = create_item(type, banana_item, locale, authorised_client_data)
        expect(response.status).to eq 409
      end

      def update_publish_and_request_PT_item(type, bananarama_id)
        update_item(type, {id: bananarama_id, title: 'portuguese bananarama'}, authorised_client_data, 'pt')
        content_updated

        portuguese_resource = get_draft_translated_item_by_id(type, bananarama_id, 'pt')
        version = portuguese_resource[:version]
        publish_single_content_item(type, bananarama_id, authorised_client_data, version, 'pt')
        content_updated

        item = get_public_translated_item_by_id(type, bananarama_id, 'pt')
        expect(item[:title]).to eq 'portuguese bananarama'
      end

      def delete_canonical_item_in_draft_and_public(bananarama_id, type)
        response = delete_item_with_locale(type, bananarama_id, authorised_client_data, 'es')
        expect(response.status).to eq 204
        content_updated

        expect(get_public_translated_response_status_code_for(type, bananarama_id, 'es')).to eq 404
      end

      def publish_ES_item(bananarama_id, type)
        spanish_resource = get_draft_translated_item_by_id(type, bananarama_id, 'es')
        version = spanish_resource[:version]
        publish_single_content_item(type, bananarama_id, authorised_client_data, version, 'es')

        content_updated
      end

      def delete_EN_in_draft(bananarama_id, type)
        response = delete_item_with_locale(type, bananarama_id, authorised_client_data, 'en')
        expect(response.status).to eq 204

        content_updated

        expect(get_draft_translated_response_status_code_for(type, bananarama_id, 'en')).to eq 200
      end
    end

  end
end
