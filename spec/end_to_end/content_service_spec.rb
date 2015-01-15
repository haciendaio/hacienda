require_relative 'support/end_to_end_test_helper'

require_relative '../../app/lib/content_digest'
require_relative '../../app/metadata/metadata'
require_relative '../../spec/shared/navigation'
require_relative '../shared/metadata_builder'
require_relative '../../app/metadata/metadata_factory'

require_relative '../../spec/fake_settings'
require_relative '../../spec/utilities/fake_config_loader'

require_relative '../../spec/shared/key_mocking'

module Hacienda
  module Test
    describe 'Content service' do

      include Navigation
      include FakeSettings
      include KeyMocking

      let(:item_for_saving) do
        {
            id: 'editable-item',
            subtitle: "A subtitle that changed on #{Time.now}",
            title: "A title that was confirmed on #{Time.now}",
            date: @date,
            location: "I still do not want to live here on #{Time.now}",
            content_body_html: "<p>Interesting <b>stuff</b> written on #{Time.now}</p>"
        }
      end

      let(:existing_item) do
        {
            id: 'editable-item',
            subtitle: 'subtitle',
            title: 'title',
            date: @date,
            location: 'location',
            content_body_html: '<p>Boring stuff</p>'
        }
      end

      let(:authorised_client_data) do {
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

        @non_authorised_client_data = {
            secret: 'WRONG SECRET',
            nonce: 'WRONG',
            client_id: 'WRONG',
            timestamp: 'WRONG'
        }

        @date = '09/04/2013'

        add_credentials_to_test_keys @client_id, @client_secret
      end

      after :all do
        @service_runner.stop unless @service_runner.nil?
      end

      context 'content item updates' do

        it 'should save the inline fields of an item' do
          add_test_content_item('paper', 'editable-item', 'cn', existing_item)

          response = update_item('paper', item_for_saving, authorised_client_data, 'cn')

          expect(response.status).to eq 200
          expect(response.headers['ETag']).not_to be_nil, 'The ETag with content version should be present'
          expect(response.headers['Content-Type']).to eq('application/json'), 'should be json - otherwise nginx might gzip and strip etag :('

          github_tells_service_that_content_updated

          updated_item = get_draft_translated_item_by_id('paper', 'editable-item', 'cn')
          updated_item.should include item_for_saving
        end

       it 'should return a 401 when the authorisation is incorrect' do
          item_we_are_not_allowed_to_update = {id: 'test-authorisation-failure'}

          response = update_item('paper', item_we_are_not_allowed_to_update, @non_authorised_client_data, 'en')

          response.status.should eq 401
        end

        it 'should return a 200 when the authorisation is correct' do
          add_test_content_item('paper', 'test-authorisation-success', 'pt', existing_item)

          updated_item = {id: 'test-authorisation-success'}
          response = update_item('paper', updated_item, authorised_client_data, 'pt')

          response.status.should eq 200
        end

        it 'should publish only a single existing paper item' do
          published_title = "This single item was published at #{Time.now}"
          content_body = "<p>An item that needs the world to know about it #{Time.now}</p>"

          unpublished_item = {
              id: 'single-paper-item-to-publish',
              title: published_title,
              content_body_ref: 'single-paper-item-to-publish-content-body.html',
              date: @date,
              content_body_html: content_body
          }

          version = add_test_content_item('paper', 'single-paper-item-to-publish', 'cn', unpublished_item)

          publish_result = publish_single_content_item('paper', 'single-paper-item-to-publish', authorised_client_data, version, 'cn')
          publish_result.status.should == 200

          github_tells_service_that_content_updated.body.should eq 'content updated'

          public_item = get_public_translated_item_by_id('paper', 'single-paper-item-to-publish', 'cn')
          public_item[:title].should eq published_title
          public_item[:date].should eq @date
          public_item[:content_body_html].should eq(content_body)
        end
      end

      context 'content item delete' do

        it 'should delete an item' do
          type = 'bananas'
          id = 'good_banana'
          add_test_content_item(type, id, 'en', existing_item)
          add_test_content_item(type, id, 'en', existing_item, 'public')

          response = delete_item_with_locale(type, id, authorised_client_data, 'en')
          expect(response.status).to eq 204

          github_tells_service_that_content_updated.body.should eq 'content updated'

          expect(get_draft_response_status_code_for(type, id, 'en')).to eq 404
          expect(get_public_response_status_code_for(type, id, 'en')).to eq 404

          response = delete_item_with_locale(type, id, authorised_client_data, 'en')
          expect(response.status).to eq 404
        end

      end

      def add_test_content_item(type, id, locale, data, status = 'draft')
        upsert_content(@test_github, MetadataFactory.new.create(id, locale, DateTime.new(2014, 1, 1).to_s, 'some author').to_json, "metadata/#{type}/#{id}.json")
        json_file = upsert_content(@test_github, data.to_json, "#{status}/#{locale}/#{type}/#{id}.json")
        html_file = upsert_content(@test_github, data[:content_body_html],"#{status}/#{locale}/#{type}/#{id}-content-body.html")
        ContentDigest.new('', nil, nil).generate_digest([json_file.sha, html_file.sha])
      end

    end

  end
end
