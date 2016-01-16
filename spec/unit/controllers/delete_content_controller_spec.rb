require_relative '../unit_helper'
require_relative '../../../spec/fake_settings'
require_relative 'service_http_response_double'
require_relative '../../../app/exceptions/not_found_exception'
require_relative '../../../app/controllers/delete_content_controller'
require 'json'

module Hacienda
  module Test
    describe 'delete' do

      let(:log) { double('Log', info: '') }
      let(:metadata_factory) { double('MetadataFactory', from: metadata) }
      let(:metadata) { double('Metadata', has_languages?: false, remove_for_locale: nil) }
      let(:github) { double('github', delete_content: '', get_content: double('GitFile', content: '{}'), create_content: {''=>''}) }
      let(:file_provider) { double('FilePathProvider', draft_json_path_for: '', public_json_path_for: '', metadata_path_for: 'path/for/metadata') }

      let(:delete_content_controller) { DeleteContentController.new(github, log, file_provider, metadata_factory) }

      describe 'delete localised item' do

        let(:type) { 'pears' }
        let(:id) { 'yellow_pear' }

        it 'should delete the json and html files for the item in public' do
          public_path = 'public/pt/pears/yellow_pear.json'
          file_provider.stub(:public_json_path_for).with(id, type, 'pt').and_return(public_path)

          delete_content_controller.delete(id, type, 'pt')

          expect(file_provider).to have_received(:public_json_path_for).with(id, type, 'pt')
          expect(github).to have_received(:delete_content).with(public_path, 'Content item deleted')
        end

        it 'should delete the json and html files for the item in draft' do
          draft_path = 'draft/cn/pears/yellow_pear.json'
          file_provider.stub(:draft_json_path_for).with(id, type, 'cn').and_return(draft_path)

          delete_content_controller.delete(id, type, 'cn')

          expect(file_provider).to have_received(:draft_json_path_for).with(id, type, 'cn')
          expect(github).to have_received(:delete_content).with(draft_path, 'Content item deleted')
        end

        it 'should delete json and html for a content item in draft even if there is no public version' do
          draft_path = 'draft/cn/pears/yellow_pear.json'
          public_path = 'public/cn/pears/yellow_pear.json'

          file_provider.stub(:draft_json_path_for).with(id, type, 'cn').and_return(draft_path)
          file_provider.stub(:public_json_path_for).with(id, type, 'cn').and_return(public_path)

          github.stub(:delete_content).with(public_path, anything).and_raise(Errors::NotFoundException)

          response = delete_content_controller.delete(id, type, 'cn')

          expect(response.code).to eq 204
        end

        it 'should delete metadata for the deleted item' do
          metadata_path = 'metadata/pears/yellow_pear.json'

          file_provider.stub(:metadata_path_for).with(id, type).and_return(metadata_path)

          delete_content_controller.delete(id, type, 'de')

          expect(github).to have_received(:get_content).with(metadata_path)
          expect(github).to have_received(:delete_content).with(metadata_path, 'Deleted metadata file')
        end

        it 'should update metadata for the deleted item, if there is still translated versions of the item' do
          metadata_path = 'metadata/pears/yellow_pear.json'

          metadata.stub(:has_languages?).and_return(true)
          metadata.stub(:to_json).and_return('some json representation')
          file_provider.stub(:metadata_path_for).with(id, type).and_return(metadata_path)

          delete_content_controller.delete(id, type, 'pt')

          expect(metadata).to have_received(:remove_for_locale).with('pt')
          expect(github).to have_received(:create_content).with('Updated metadata file', metadata_path => 'some json representation')
        end

        it 'should set the response code to 404 when there is no item in draft or public' do
          github.stub(:delete_content).and_raise(Errors::NotFoundException)
          response = delete_content_controller.delete(id, type)
          expect(response.code).to eq 404
        end

        it 'should return 204 even when the metadata file does not exist' do
          metadata_path = 'metadata/pears/yellow_pear.json'
          file_provider.stub(:metadata_path_for).with(id, type).and_return(metadata_path)
          github.stub(:get_content).with(metadata_path).and_raise(Errors::NotFoundException)
          github.stub(:delete_content).with(metadata_path, anything).and_raise(Errors::NotFoundException)

          response = delete_content_controller.delete(id, type)

          expect(response.code).to eq 204
        end

      end

      describe 'delete entire item' do

        let(:type) { 'pears' }
        let(:id) { 'yellow_pear' }

        let(:github) { double('github', get_content: nil, delete_content: nil) }
        let(:datetime) { DateTime.new(2014, 1, 1) }

        subject { DeleteContentController.new(github, log) }

        it 'should delete the metadata file' do

          github.stub(:get_content).with('metadata/type/id.json').and_return(
              double(content: MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author').to_json)
          )

          subject.delete_all('type', 'id')

          expect(github).to have_received(:delete_content).with('metadata/type/id.json')
        end

        it 'should delete all draft content referenced in the metadata file' do

          metadata = MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author')
                                        .add_draft_language('pt')
                                        .add_draft_language('cn')
                                        .to_json

          github.stub(:get_content).with('metadata/type/id.json').and_return(double('gitfile', content: metadata))

          subject.delete_all('type', 'id')

          expect(github).to have_received(:delete_content).with('draft/en/type/id.json')
          expect(github).to have_received(:delete_content).with('draft/pt/type/id.json')
          expect(github).to have_received(:delete_content).with('draft/cn/type/id.json')
        end

        it 'should delete all the public content referenced in metadata file' do
          metadata = MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author')
                                        .add_public_language('en')
                                        .add_public_language('pt')
                                        .add_public_language('cn')
                                        .to_json

          github.stub(:get_content).with('metadata/type/id.json').and_return(double('gitfile', content: metadata))

          subject.delete_all('type', 'id')

          expect(github).to have_received(:delete_content).with('public/en/type/id.json')
          expect(github).to have_received(:delete_content).with('public/pt/type/id.json')
          expect(github).to have_received(:delete_content).with('public/cn/type/id.json')

        end

        it 'should not delete any content if the metadata fails to delete' do
          metadata = MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author')
                                    .add_public_language('en')
                                    .to_json

          github.stub(:delete_content).with('metadata/type/id.json').and_raise(StandardError)

          github.stub(:get_content).with('metadata/type/id.json').and_return(double('gitfile', content: metadata))

          expect {
            subject.delete_all('type', 'id')
          }.to raise_error StandardError

          expect(github).not_to have_received(:delete_content).with(start_with('public'))
          expect(github).not_to have_received(:delete_content).with(start_with('draft'))
        end

        it 'should return a 404 status when the item trying to delete does not exist' do
          github.stub(:get_content).and_raise(Errors::NotFoundException)

          response = subject.delete_all('type', 'id')
          expect(response.code).to eq 404
        end

        it 'should return a 404 status when any of the language versions mentioned in the item metadata do not exist' do
          metadata = MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author')
                                        .add_public_language('en')
                                        .to_json

          github.stub(:get_content).with('metadata/type/id.json').and_return(double('gitfile', content: metadata))
          github.stub(:delete_content).and_raise(Errors::NotFoundException)


          response = subject.delete_all('type', 'id')
          expect(response.code).to eq 404
        end

        it 'should return a 404 status when the item trying to delete does not exist' do
          metadata = MetadataFactory.new.create('id', 'en', datetime.to_s, 'some author')
                                        .add_public_language('en')
                                        .to_json

          github.stub(:get_content).with('metadata/type/id.json').and_return(double('gitfile', content: metadata))
          response = subject.delete_all('type', 'id')
          expect(response.code).to eq 204
        end


      end
    end
  end
end