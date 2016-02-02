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
      let(:content_digest) { double('content_digest', generate_digest: 'DIGEST') }

      let(:existing_version) {
        versions = { draft: 'existing-draft-version', public: 'existing-public-version' }
        {id: 'some-id', versions: versions}
      }
      let(:content) { double(Content, exists_in?: true, write_to: nil, id: 'the id')}
      let(:content_factory) { double(ContentFactory, instance: content) }

      let(:content_store) { double('content store', find_one: existing_version)}

      let(:locale) { 'es' }
      let(:author) { 'new author' }
      let(:type) { 'mammal' }
      let(:content_id) { 'reindeer' }
      let(:new_content) { { 'id' => content_id, 'type' => type, 'prancer_html' => 'antler' }.to_json }

      subject { UpdateContentController.new(file_system, content_digest, content_store, double('Log', info:nil), content_factory: content_factory) }

      it 'instantiates content model and writes it to file system' do
        allow(content_factory)
          .to receive(:instance)
          .with(content_id, new_content, type: type, locale: locale)
          .and_return(content)

        subject.update(type, content_id, new_content, locale, author)

        expect(content).to have_received(:write_to)
          .with(file_system, author, include('modified'), content_digest)
      end

      it 'returns a 404 when content item does not exist' do
        allow(content_factory).to receive(:instance).and_return(content)
        allow(content).to receive(:exists_in?).with(file_system).and_return false

        response = subject.update(type, content_id, new_content, locale, author)

        expect(response.code).to eq 404
      end

      context 'no existing public content' do
        before {
          content_store.stub(:find_one).with(type, content_id, locale).
              and_raise(Errors::FileNotFoundError.new 'oops no public version')
        }

        it 'returns updated draft version, also as etag, when update successful' do
          allow(content).to receive(:write_to)
            .and_return('updated-version')

          response = subject.update(type, content_id, new_content, locale, author)

          updated_resource = parse_json(response.body)

          expect(response.etag).to eq 'updated-version'
          expect(updated_resource[:versions]).to eq(draft: 'updated-version', public: nil)
        end
      end

      context 'there is an existing public version' do
        let(:existing_content) {
          {
            versions: {
              draft: 'previous-version',
              public: 'public-version'
            }
          }
        }

        before {
          allow(content).to receive(:write_to).and_return('updated-version')
          content_store.stub(:find_one).with(type, content_id, locale).and_return(existing_content)
        }

        it 'return the versions when update successful' do
          response = subject.update(type, content_id, new_content, locale, author)

          updated_resource = parse_json(response.body)

          expect(response.etag).to eq 'updated-version'
          expect(response.content_type).to eq 'application/json'
          expect(updated_resource[:versions]).to eq(draft: 'updated-version', public: 'public-version')
        end
      end


      def parse_json(json)
        JSON.parse(json, symbolize_names: true)
      end
    end
  end
end
