require_relative '../../unit_helper'
require_relative '../../../../app/stores/content_handlers/version_content_handler'
require_relative '../../../../app/services/file_path_provider'
require_relative '../../../../app/stores/content_store'

module Hacienda
  module Test

    describe VersionContentHandler do

      let(:content_digest) { double('ContentDigest', item_version: nil)}
      let(:file_path_provider) { FilePathProvider.new }

      context 'draft' do

        it 'should set the version in the content hash when in draft based upon json and potential html file' do
          content_digest.stub(:item_version).and_return('version')

          data = {}
          query_new = ContentQuery.new(:draft, 'pt', 'type', 'id')

          VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

          expect(content_digest).to have_received(:item_version).with('draft/pt/type/id.json', 'draft/pt/type/id-content-body.html')
          expect(data[:version]).to eq('version')
        end

        it 'should populate the versions array with draft version' do
          content_digest.stub(:item_version).and_return('version')

          data = {}
          query_new = ContentQuery.new(:draft, 'pt', 'type', 'id')

          VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

          expect(data[:versions][:draft]).to eq('version')
        end

        it 'should populate the versions array with the draft and public versions where both versions are available' do
          content_digest.stub(:item_version).with('draft/pt/type/id.json', 'draft/pt/type/id-content-body.html').and_return('draft-version')
          content_digest.stub(:item_version).with('public/pt/type/id.json', 'public/pt/type/id-content-body.html').and_return('public-version')

          data = {}
          query_new = ContentQuery.new(:draft, 'pt', 'type', 'id')
          VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

          expect(data[:versions][:draft]).to eq('draft-version')
          expect(data[:versions][:public]).to eq('public-version')
        end

        it 'should populate the versions array with the draft and nil for public when there is no version' do
          content_digest.stub(:item_version).with('draft/pt/type/id.json', 'draft/pt/type/id-content-body.html').and_return('draft-version')

          data = {}
          query_new = ContentQuery.new(:draft, 'pt', 'type', 'id')
          VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

          expect(data[:versions][:draft]).to eq('draft-version')
          expect(data[:versions][:public]).to eq(nil)
        end

        context 'querying collection' do
          it 'should not add the version even in draft mode when dealing with collections, because it takes to long' do
            content_digest.stub(:item_version).and_return('version')

            data = {}
            query_new = ContentQuery.new(:draft, 'en', 'type', 'id', :collection)

            VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

            expect(content_digest).to have_received(:item_version).with('draft/en/type/id.json', 'draft/en/type/id-content-body.html')
            expect(data[:version]).to eq 'version'
          end
        end

      end

      it 'should not lookup the version nor set it in the content hash when not in draft' do
        content_digest.stub(:item_version).and_return('version')

        data = {}
        query_new = ContentQuery.new(:public, 'en', 'type', 'id')

        VersionContentHandler.new(content_digest, file_path_provider).process!(data, query_new)

        expect(content_digest).to_not have_received(:item_version)
        expect(data[:version]).to be_nil
      end


    end

  end
end