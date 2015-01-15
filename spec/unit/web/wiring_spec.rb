require_relative '../unit_helper'

require_relative '../../../app/web/wiring'

require_relative '../../../spec/fake_settings'

module Hacienda
  module Test

    class StubApp
      include Wiring
      include FakeSettings

      def settings
        fake_multiple_settings_with(:content_directory_path => 'content/directory/path')
      end

      def response
        Object.new
      end

      class FakeRequest
        def query_string
          nil
        end

        def env
          {'rack.request.query_hash' => {}}
        end

      end

      def request
        FakeRequest.new
      end

    end

    describe Wiring do

      let (:app) { StubApp.new }

      context('content store') do

        it 'should return a draft content store' do
          app.draft_content_store.should be_a ContentStore
          expect(app.draft_content_store.instance_variable_get(:@state)).to be :draft
        end

        it 'should return a public content store' do
          app.public_content_store.should be_a ContentStore
          expect(app.public_content_store.instance_variable_get(:@state)).to be :public
        end

        it 'should use the query runner in the content store' do
           expect(app.public_content_store.instance_variable_get(:@query)).to be_a QueryRunner
        end
      end

      it 'should return content service controller' do
        expect(app.create_content_controller).to be_a CreateContentController
        expect(app.create_content_controller.instance_variable_get(:@github)).to be_a Github
      end

      it 'should return a content update controller using draft content store... cos public doesnt return version info
:(' do
        expect(app.update_content_controller).to be_a UpdateContentController
        expect(app.update_content_controller.instance_variable_get(:@content_store).instance_variable_get(:@state)).to eq :draft
      end

      it 'should return github with a github_client' do
        github = app.github
        expect(github).to be_a Github
        expect(github.instance_variable_get(:@github_client)).to be_a GithubClient
      end

      it 'should return a content file store' do
        file_data_store = app.content_file_store
        file_data_store.should be_a FileDataStore
        file_data_store.instance_variable_get(:@data_dir).should eq 'content/directory/path'
      end

      it 'should return the file handlers' do
        file_handlers = app.file_handlers
        expect(file_handlers).to be_a Array
        expect(file_handlers).to have(1).items
        expect(file_handlers.first).to be_a ReferencedFileHandler
      end

      it 'should return the content handlers' do
        content_handlers = app.content_handlers
        expect(content_handlers).to be_a Array
        expect(content_handlers).to have(2).items
        expect(content_handlers[0]).to be_a VersionContentHandler
        expect(content_handlers[1]).to be_a EnsureIdHandler
      end

      it 'should return a local git repo for the content repository' do
        local_content_repo = app.local_content_repo
        local_content_repo.should be_a LocalGitRepo
        local_content_repo.instance_variable_get(:@data_dir).should eq 'content/directory/path'
      end

      it 'should return a content digest' do
        content_digest = app.content_digest
        content_digest.should be_a ContentDigest
      end

      it 'should return a File Path Provider' do
        file_path_provider = app.file_path_provider
        file_path_provider.should be_a FilePathProvider
      end

      it 'should return a content item publisher' do
        publish_content_controller = app.publish_content_controller
        publish_content_controller.should be_a PublishContentController
        publish_content_controller.instance_variable_get(:@log).should be_a Log
      end

      it 'should return a content delete controller' do
        expect(app.delete_content_controller).to be_a DeleteContentController
      end

    end

  end
end
