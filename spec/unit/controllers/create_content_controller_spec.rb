require_relative '../unit_helper'
require_relative '../../../app/controllers/create_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/metadata/metadata_factory'
require_relative 'service_http_response_double'

module Hacienda
  module Test

    describe CreateContentController do

      let(:content_digest) { double('content_digest', generate_digest: 'version') }
      let(:github) { double('github', create_content: double(sha: 'version'), content_exists?: false) }

      subject { CreateContentController.new(github, content_digest) }

      it 'should create a html file and json file from the data for a specific locale' do
        item_json = {id: 'item-id', title: 'Item', content_body_html: '<p>body</p>'}.to_json
        processed_json = {id: 'item-id', title: 'Item', content_body_ref: 'item-id-content-body.html'}.to_json

        subject.create('news', item_json, 'cn', 'some author')

        expect(github).to have_received(:create_content).with(anything, 'draft/cn/news/item-id-content-body.html' => '<p>body</p>')
        expect(github).to have_received(:create_content).with(anything, 'draft/cn/news/item-id.json' => processed_json)
      end

      it 'should return a 409 if content exists' do
        github.stub(:content_exists?).with('metadata/news/an_id.json').and_return(true)

        response = subject.create('news', {id: 'an_id'}.to_json, 'en', 'some author')

        expect(response.code).to eq 409
        expect(github).to_not have_received(:create_content)
      end

      it 'should create a metadata for an item that does not exists' do
        datetime = double('DateTime', to_s: 'some-date-time')
        DateTime.stub(:now).and_return(datetime)

        metadata = MetadataFactory.new.create('an_id', 'pt', datetime, 'some author')

        subject.create('news', {id: 'an_id'}.to_json, 'pt', 'some author')
        expect(github).to have_received(:create_content).with(anything, 'metadata/news/an_id.json' => metadata.to_json)
      end

      describe 'response' do

        it 'should return the version of the created file' do
          github.stub(:create_content).with(anything, 'draft/en/news/item-id-content-body.html' => anything).and_return(double(sha: 'html_v1'))
          github.stub(:create_content).with(anything, 'draft/en/news/item-id.json' => anything).and_return(double(sha: 'json_v1'))

          content_digest.stub(:generate_digest).with(%w(json_v1 html_v1)).and_return('a_version')

          response = subject.create('news', {id: 'item-id', content_body_html: ''}.to_json, 'en', 'some author')

          expect(response.etag).to eq 'a_version'
        end

        it 'should return the path for the content item ' do
          response = subject.create('news', {id:  'new-id-for-create'}.to_json, 'es', 'some author')
          expect(response.location).to eq 'news/new-id-for-create/es'
        end

        it 'should return 201 created status' do
          response = subject.create('news', {id: 'new-id-for-create'}.to_json, 'de', 'some author')
          expect(response.code).to eq 201
        end

        it 'should set the content type to json' do
          response = subject.create('news', {id: 'new-id-for-create'}.to_json, 'en', 'some author')
          expect(response.content_type).to eq 'application/json'
        end

        it 'return a draft version and a nil public version' do
          github.stub(:create_content).with(anything, 'draft/en/news/new-id-for-create.json' => anything).and_return(double(sha: 'json_v1'))
          content_digest.stub(:generate_digest).with(%w(json_v1)).and_return('a_version')

          result = subject.create('news', {id: 'new-id-for-create'}.to_json, 'en', 'some author')

          body = JSON.parse(result.body, symbolize_names: true)

          expect(body[:versions][:draft]).to eq 'a_version'
          expect(body[:versions][:public]).to be_nil
        end

      end

    end
  end
end