require_relative '../unit_helper'
require 'json'

require_relative '../../../app/controllers/update_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/metadata/metadata_factory'
require_relative '../../shared/metadata_builder'
require_relative 'service_http_response_double'

module Hacienda
  module Test

    describe UpdateContentController do

      let(:json_file) { double('json_file', content: '{}', sha: 'json_v1') }
      let(:html_file) { double('html_file', content: '', sha: 'html_v1') }

      let(:github) { double('github', create_content: json_file, content_exists?: true) }
      let(:content_digest) { double('content_digest', generate_digest: 'DIGEST') }

      let(:metadata_factory) { MetadataFactory.new }
      let(:datetime) { DateTime.new(2014, 1, 1)}
      let(:existing_version) {
        versions = { draft: 'existing-draft-version', public: 'existing-public-version' }
        {id: 'some-id', versions: versions}
      }

      let(:content_store) { double('content store', find_one: existing_version)}
      subject { UpdateContentController.new(github, content_digest, content_store, double('Log', info:nil)) }

      before :each do
        github.stub(:get_content).and_return(json_file, html_file)
      end

        it 'should update content when locale already exists' do
          metadata = metadata_factory.create('reindeer', 'es', datetime.to_s, 'old author')

          github.stub(:get_content).with('metadata/mammal/reindeer.json').and_return(double(content: metadata.to_json))

          new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

          subject.update('mammal', 'reindeer', new_content, 'es', 'new author')

          expect(github).to have_received(:create_content).with('metadata/mammal/reindeer.json', anything, anything)
          expect(github).to have_received(:create_content).with('draft/es/mammal/reindeer-prancer.html', 'antler', anything)
          expect(github).to have_received(:create_content).with('draft/es/mammal/reindeer.json', {
              'id' => 'reindeer',
              'type' => 'mammal',
              'prancer_ref' => 'reindeer-prancer.html'
          }.to_json, anything)
      end

      it 'should update content and metadata when locale does not exist' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json
        new_datetime = double('DateTime', to_s:'some-date-time')
        DateTime.stub(:now).and_return(new_datetime)

        github.stub(:get_content).with('metadata/mammal/reindeer.json').and_return(double(content: metadata.to_json))

        subject.update('mammal', 'reindeer', new_content, 'es', 'new author')

        expected_metadata = MetadataBuilder.new
            .with_id('reindeer')
            .with_canonical('en')
            .with_draft_languages('en','es')
            .with_last_modified('en', datetime)
            .with_last_modified('es', new_datetime)
            .with_last_modified_by('en', 'some author')
            .with_last_modified_by('es', 'new author')
            .build

        expect(github).to have_received(:create_content).with('metadata/mammal/reindeer.json', expected_metadata.to_json, anything)
        expect(github).to have_received(:create_content).with('draft/es/mammal/reindeer-prancer.html', 'antler', anything)
        expect(github).to have_received(:create_content).with('draft/es/mammal/reindeer.json', {
            'id' => 'reindeer',
            'type' => 'mammal',
            'prancer_ref' => 'reindeer-prancer.html'
        }.to_json, anything)
      end

      it 'should return a 404 when no metadata for content' do
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        github.stub(:content_exists?).with('metadata/mammal/reindeer.json').and_return(false)

        response = subject.update('mammal', 'reindeer', new_content, 'es', 'some author')

        expect(response.code).to eq 404
        expect(github).to_not have_received(:create_content)
      end

      it 'should return copy of resource when update successful and no existing public content' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        github.stub(:get_content).with('metadata/mammal/reindeer.json').and_return(double(content: metadata.to_json))
        github.stub(:create_content).and_return(html_file, json_file)
        content_store.stub(:find_one).with('mammal', 'reindeer', 'en').
          and_raise(Errors::FileNotFoundError.new 'oops no public version')
        content_digest.stub(:generate_digest).with(%w(json_v1 html_v1)).and_return('updated-version')

        response = subject.update('mammal', 'reindeer', new_content, 'en', 'some author')
        updated_resource = parse_json(response.body)

        expect(response.etag).to eq 'updated-version'
        expect(updated_resource[:versions]).to eq(draft: 'updated-version', public: nil)
      end

      it 'should return the versions when update successful and there is existing public content' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')
        reindeer = { 'id' => 'reindeer', 'type' => 'mammal' }
        new_content = reindeer.merge('prancer_html' => 'antler').to_json
        existing_content = reindeer.merge({ versions: {
            draft: 'previous-version', public: 'public-version'
        }})

        content_store.stub(:find_one).with('mammal', 'reindeer', 'en').and_return(existing_content)
        github.stub(:get_content).with('metadata/mammal/reindeer.json').and_return(double(content: metadata.to_json))
        github.stub(:create_content).and_return(html_file, json_file)
        content_digest.stub(:generate_digest).with(%w(json_v1 html_v1)).and_return('updated-version')

        response = subject.update('mammal', 'reindeer', new_content, 'en', 'some author')
        updated_resource = parse_json(response.body)

        expect(response.etag).to eq 'updated-version'
        expect(response.content_type).to eq 'application/json'
        expect(updated_resource[:versions]).to eq(draft: 'updated-version', public: 'public-version')
      end


      it 'should update the last modified date' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')

        github.stub(:get_content).with('metadata/mammal/reindeer.json').and_return(double(content: metadata.to_json))

        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        new_datetime = double('DateTime', to_s: 'some-date-time')
        DateTime.stub(:now).and_return(new_datetime)

        subject.update('mammal', 'reindeer', new_content, 'en', 'some author')

        expected_metadata = MetadataBuilder.new
            .with_id('reindeer')
            .with_canonical('en')
            .with_draft_languages('en')
            .with_last_modified('en', new_datetime)
            .with_last_modified_by('en', 'some author')
        expect(github).to have_received(:create_content).with('metadata/mammal/reindeer.json', expected_metadata.build.to_json, anything)
      end

      def parse_json(json)
        JSON.parse(json, symbolize_names: true)
      end
    end
  end
end
