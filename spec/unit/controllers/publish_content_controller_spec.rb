require_relative '../unit_helper'
require_relative '../../../app/controllers/publish_content_controller'
require_relative '../../../app/services/file_path_provider'
require_relative '../../../app/exceptions/not_found_exception'
require_relative '../../../app/exceptions/precondition_failed_error'
require_relative '../../../app/metadata/metadata_factory'
require_relative 'service_http_response_double'

require 'json'

module Hacienda
  module Test

    describe PublishContentController do

      let(:github) { double('github', write_files: {'' => {}}, update_content: nil, content_exists?: true, get_content: nil) }
      let(:content_digest) { double('content_digest', generate_digest: 'correct_version') }

      let(:log) { double('log', warn: nil) }

      let(:draft_json_file) {
        double('json_file', content: { 'earl_grey_ref' => 'tea-id-earl-grey.html' }.to_json, sha: 123)
      }

      let(:earl_grey_html) { double('html_file', content: 'Earl Grey', sha: 456) }
      let(:metadata_factory) { MetadataFactory.new }
      let(:datetime) { DateTime.new(2014, 1, 1) }

      subject { PublishContentController.new(github, content_digest, log) }

      context 'successful publish' do

        let(:metadata) { metadata_factory.create('teas', 'es', datetime.to_s, 'some author') }

        before :each do
          github.stub(:get_content).with('metadata/teas/tea-id.json').and_return(double('metadata_file', content: metadata.to_json))
          github.stub(:get_content).with('draft/es/teas/tea-id.json').and_return(draft_json_file)
          github.stub(:get_content).with('draft/es/teas/tea-id-earl-grey.html').and_return(earl_grey_html)
        end

        it 'should publish all referenced html files' do
          subject.publish('teas', 'tea-id', 'correct_version', 'es')
          expect(github).to have_received(:write_files).with(anything, 'public/es/teas/tea-id-earl-grey.html' => 'Earl Grey')
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
          expect(github).to have_received(:write_files).with(anything, 'metadata/teas/tea-id.json' => metadata.add_public_language('es').to_json)
        end

        it 'should not add the public language if it already exists in the metadata' do
          metadata = metadata_factory.create('teas', 'es', datetime.to_s, 'some author').add_public_language('es')
          github.stub(:get_content).with('metadata/teas/tea-id.json').and_return(double('metadata_file', content: metadata.to_json))

          subject.publish('teas', 'tea-id', 'correct_version', 'es')
          expect(github).to have_received(:write_files).with(anything, 'metadata/teas/tea-id.json' => metadata.to_json)
        end

      end

      context 'version mismatch' do

        let(:metadata) { metadata_factory.create('teas', 'es', datetime.to_s, 'some author') }

        before :each do
          github.stub(:get_content).with('metadata/teas/tea-id.json').and_return(double('metadata', content: metadata.to_json))
          github.stub(:get_content).with('draft/es/teas/tea-id.json').and_return(draft_json_file)
          github.stub(:get_content).with('draft/es/teas/tea-id-earl-grey.html').and_return(earl_grey_html)
        end

        it 'should not publish files and throw exception' do
          expect {
            subject.publish('teas', 'tea-id', 'wrong_version', 'es')
          }.to raise_error(Errors::PreconditionFailedError)

          expect(github).not_to have_received(:write_files)
        end

      end

    end
  end
end
