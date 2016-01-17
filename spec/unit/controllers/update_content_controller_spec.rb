require_relative '../unit_helper'
require 'json'

require_relative '../../../app/controllers/update_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/metadata/metadata_factory'
require_relative '../../shared/metadata_builder'
require_relative 'service_http_response_double'
require_relative '../github/in_memory_file_system'

module Hacienda
  module Test

    describe UpdateContentController do

      let(:file_system) { InMemoryFileSystem.new }
      let(:files) { file_system.test_api }
      let(:content_digest) { double('content_digest', generate_digest: 'DIGEST') }

      let(:metadata_factory) { MetadataFactory.new }
      let(:datetime) { DateTime.new(2014, 1, 1)}
      let(:existing_version) {
        versions = { draft: 'existing-draft-version', public: 'existing-public-version' }
        {id: 'some-id', versions: versions}
      }

      let(:content_store) { double('content store', find_one: existing_version)}
      subject { UpdateContentController.new(file_system, content_digest, content_store, double('Log', info:nil)) }

      it 'should update content when locale already exists' do
        metadata = metadata_factory.create('reindeer', 'es', datetime.to_s, 'old author')

        files.setup 'metadata/mammal/reindeer.json' => metadata.to_json

        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        subject.update('mammal', 'reindeer', new_content, 'es', 'new author')

        expect(files.content_of 'draft/es/mammal/reindeer-prancer.html').to eq 'antler'
        expect(files.content_of 'draft/es/mammal/reindeer.json').to eq({
                                                                          'id' => 'reindeer',
                                                                          'type' => 'mammal',
                                                                          'prancer_ref' => 'reindeer-prancer.html'
                                                                        }.to_json)
      end

      it 'should update content and metadata when locale does not exist' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json
        new_datetime = double('DateTime', to_s:'some-date-time')
        DateTime.stub(:now).and_return(new_datetime)

        files.setup 'metadata/mammal/reindeer.json' => metadata.to_json

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

        expect(files.content_of 'draft/es/mammal/reindeer-prancer.html').to eq 'antler'
        expect(files.content_of 'draft/es/mammal/reindeer.json').to eq({
                                                                  'id' => 'reindeer',
                                                                  'type' => 'mammal',
                                                                  'prancer_ref' => 'reindeer-prancer.html'
                                                              }.to_json)
        expect(files.content_of 'metadata/mammal/reindeer.json').to eq expected_metadata.to_json
      end

      it 'should return a 404 when no metadata file exists for content' do
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        response = subject.update('mammal', 'reindeer', new_content, 'es', 'some author')

        expect(response.code).to eq 404
        expect(files).to be_empty
      end

      it 'should return copy of resource when update successful and no existing public content' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')
        new_content = { 'id' => 'reindeer', 'type' => 'mammal', 'prancer_html' => 'antler' }.to_json

        files.setup 'metadata/mammal/reindeer.json' => metadata.to_json
        files.setup 'draft/en/mammal/reindeer.html' => '<html/>', 'draft/en/mammal/reindeer.json' => '{}'

        content_store.stub(:find_one).with('mammal', 'reindeer', 'en').
          and_raise(Errors::FileNotFoundError.new 'oops no public version')

        content_digest.stub(:generate_digest).with([
                                                       files.sha_of('draft/en/mammal/reindeer.json'),
                                                       files.sha_of('draft/en/mammal/reindeer-prancer.html')
                                                   ]).and_return('updated-version')

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

        files.setup 'metadata/mammal/reindeer.json' => metadata.to_json
        files.setup 'draft/en/mammal/reindeer.html' => '<html/>', 'draft/en/mammal/reindeer.json' => '{}'

        content_digest.stub(:generate_digest).with([
                                                       files.sha_of('draft/en/mammal/reindeer.json'),
                                                       files.sha_of('draft/en/mammal/reindeer-prancer.html')
                                                   ]).and_return('updated-version')

        response = subject.update('mammal', 'reindeer', new_content, 'en', 'some author')
        updated_resource = parse_json(response.body)

        expect(response.etag).to eq 'updated-version'
        expect(response.content_type).to eq 'application/json'
        expect(updated_resource[:versions]).to eq(draft: 'updated-version', public: 'public-version')
      end


      it 'should update the last modified date' do
        metadata = metadata_factory.create('reindeer', 'en', datetime.to_s, 'some author')

        files.setup 'metadata/mammal/reindeer.json' => metadata.to_json

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
        expect(files.content_of 'metadata/mammal/reindeer.json').to eq expected_metadata.build.to_json
      end

      def parse_json(json)
        JSON.parse(json, symbolize_names: true)
      end
    end
  end
end
