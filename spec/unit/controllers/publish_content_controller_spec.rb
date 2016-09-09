require_relative '../../../app/controllers/publish_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/exceptions/not_found_exception'
require_relative '../../../app/exceptions/precondition_failed_error'
require_relative '../../../app/metadata/metadata_factory'
require_relative 'service_http_response_double'
require_relative '../github/in_memory_file_system'

require 'json'

module Hacienda
  module Test

    describe PublishContentController do

      let(:file_system) { InMemoryFileSystem.new }
      let(:files) { file_system.test_api }

      let(:content_digest) { double('content_digest', generate_digest: 'correct_version') }

      let(:log) { double('log', warn: nil) }

      let(:draft_json_file) {
        double('json_file', content: { 'earl_grey_ref' => 'tea-id-earl-grey.html' }.to_json, sha: 123)
      }

      let(:earl_grey_html) { double('html_file', content: 'Earl Grey', sha: 456) }
      let(:metadata_factory) { MetadataFactory.new }
      let(:datetime) { DateTime.new(2014, 1, 1) }

      subject { PublishContentController.new(file_system, content_digest, log) }

      context 'successful publish' do

        let(:metadata) { metadata_factory.create('teas', 'es', datetime.to_s, 'some author') }

        before :each do
          files.setup({
            'metadata/teas/tea-id.json' => metadata.to_json,
            'draft/es/teas/tea-id.json' => draft_json_file.content,
            'draft/es/teas/tea-id-earl-grey.html' => earl_grey_html.content
          })
        end

        it 'should publish all referenced html files' do
          subject.publish('teas', 'tea-id', 'correct_version', 'es')
          expect(files.content_of 'public/es/teas/tea-id-earl-grey.html').to eq 'Earl Grey'
        end

        it 'should return a draft version and a public version with the same sha' do
          response_body = subject.publish('teas', 'tea-id', 'correct_version', 'es').body
          published_item = JSON.parse(response_body, symbolize_names: true)

          expect(published_item[:versions][:draft]).to eq 'correct_version'
          expect(published_item[:versions][:public]).to eq 'correct_version'
        end

        it 'should have the application/json content-type in the header' do
          expect(subject.publish('teas', 'tea-id', 'correct_version', 'es').content_type).to eq 'application/json'
        end

        it 'should update the metadata when it publishes files' do
          subject.publish('teas', 'tea-id', 'correct_version', 'es')

          expect(files.content_of 'metadata/teas/tea-id.json').to eq metadata.add_public_language('es').to_json
        end

        it 'should not add the public language if it already exists in the metadata' do
          metadata = metadata_factory.create('teas', 'es', datetime.to_s, 'some author').add_public_language('es')
          files.setup 'metadata/teas/tea-id.json' => metadata.to_json

          subject.publish('teas', 'tea-id', 'correct_version', 'es')
          expect(files.content_of 'metadata/teas/tea-id.json').to eq metadata.to_json
        end

      end

      context 'version mismatch' do

        let(:metadata) { metadata_factory.create('teas', 'es', datetime.to_s, 'some author') }

        before :each do
          files.setup({
            'metadata/teas/tea-id.json' => metadata.to_json,
            'draft/es/teas/tea-id.json' => draft_json_file.content,
            'draft/es/teas/tea-id-earl-grey.html' => earl_grey_html.content
          })
        end

        it 'should not publish files and throw exception' do
          expect {
            subject.publish('teas', 'tea-id', 'wrong_version', 'es')
          }.to raise_error(Errors::PreconditionFailedError)
          expect(files).to_not have_been_written_to
        end

      end

    end
  end
end
