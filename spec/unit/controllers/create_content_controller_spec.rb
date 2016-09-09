require_relative '../unit_helper'
require_relative '../../../app/controllers/create_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/metadata/metadata_factory'
require_relative 'service_http_response_double'

module Hacienda
  module Test

    describe CreateContentController do

      let(:content_digest) { double('content_digest', generate_digest: 'version') }
      let(:github) { double('github', content_exists?: false) }

      before {
        github.stub(:write_files) do |message, items|
          items.map {|path, content|
            [path, double(sha: 'version')]
          }.to_h
        end
      }

      subject { CreateContentController.new(github, content_digest) }

      it 'should create a html file and json file from the data for a specific locale' do
        item_json = {id: 'item-id', title: 'Item', content_body_html: '<p>body</p>'}.to_json
        processed_json = {id: 'item-id', title: 'Item', content_body_ref: 'item-id-content-body.html'}.to_json

        subject.create('news', item_json, 'cn', 'some author')

        expect(github).to have_received(:write_files).with(anything, 'draft/cn/news/item-id-content-body.html' => '<p>body</p>')
        expect(github).to have_received(:write_files).with(anything, include('draft/cn/news/item-id.json' => processed_json))
      end

      it 'should return a 409 if content exists' do
        github.stub(:content_exists?).with('metadata/news/an_id.json').and_return(true)

        response = subject.create('news', {id: 'an_id'}.to_json, 'en', 'some author')

        expect(response.code).to eq 409
        expect(github).to_not have_received(:write_files)
      end

      it 'should create a metadata for an item that does not exists' do
        datetime = double('DateTime', to_s: 'some-date-time')
        DateTime.stub(:now).and_return(datetime)

        metadata = MetadataFactory.new.create('an_id', 'pt', datetime, 'some author')

        subject.create('news', {id: 'an_id'}.to_json, 'pt', 'some author')
        expect(github).to have_received(:write_files).with(anything, include('metadata/news/an_id.json' => metadata.to_json))
      end

      describe 'response' do

        let(:content) {{id: 'new-id-for-create'}.to_json}

        it 'should return the version of the created file' do
          html = 'some html'
          content = {id: 'item-id', content_body_html: html}.to_json

          github.stub(:write_files).with(anything, include('draft/en/news/item-id-content-body.html' => html)).and_return({ 'draft/en/news/item-id-content-body.html' => double(sha: 'html_v1')})
          github.stub(:write_files).with(anything, have_key('draft/en/news/item-id.json')).and_return({'draft/en/news/item-id.json' => double(sha: 'json_v1')})

          content_digest.stub(:generate_digest).with(%w(json_v1 html_v1)).and_return('the_version')

          response = subject.create('news', content, 'en', 'some author')

          expect(response.etag).to eq 'the_version'
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
          github.stub(:write_files).with(anything, include('draft/en/news/new-id-for-create.json' => content)).and_return('draft/en/news/new-id-for-create.json' => double(sha: 'json_v1'))
          content_digest.stub(:generate_digest).with(%w(json_v1)).and_return('a_version')

          result = subject.create('news', content, 'en', 'some author')

          body = JSON.parse(result.body, symbolize_names: true)

          expect(body[:versions][:draft]).to eq 'a_version'
          expect(body[:versions][:public]).to be_nil
        end

      end

    end
  end
end