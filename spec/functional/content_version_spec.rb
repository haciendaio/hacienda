require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../shared/metadata_builder'
require_relative '../../spec/shared/navigation'
require_relative 'support/fake_github_file_system'

module Hacienda
  module Test

    describe 'Content item version' do
      include Navigation

      def clear_test_repositories
        FileUtils.rm_rf TEST_REPO
      end

      before :all do
        app.set :content_directory_path, TEST_REPO
      end

      before :each do
        clear_test_repositories
      end

      context 'setup using the file system directly' do

        let(:test_content_manager) { TestContentManager.new(TEST_REPO) }
        let(:default_metadata) { MetadataBuilder.new.default.build }

        it 'should have a version' do
          item = { id: 'bill', title: 'Bill the Badger' }
          test_content_manager.add_item('draft', 'en', 'forest', 'bill', item, default_metadata)
          test_content_manager.add_ref_file('draft', 'en', 'forest', 'bill-content-body.html','<p>some html</p>')

          json_file_sha = '0c6fa4740e5f2204097933fe4fdcf0e76265d640'
          html_file_sha = '360b935eab6c5026644c3e5443b2e174cf4b5fee'

          combined_sha = Digest::SHA2.new.update(json_file_sha + html_file_sha).to_s

          expect(get_draft_translated_item_by_id('forest', 'bill', 'en')[:version]).to eq combined_sha
        end
      end

      context 'setup through content service API but using fake github' do

        before :each do
          allow_any_instance_of(app).to receive(:github_file_system).and_return(FakeGithubFileSystem.new(TEST_REPO))
        end

        let(:a_content_item) { ContentItem.new }
        let(:content) { Content.new }

        it 'should include the version of a new draft item in its locale' do
          content.add a_content_item.to_hash

          draft_item = content.get_draft(of: a_content_item.to_hash, in: a_content_item.locale)

          versions = draft_item[:versions]

          expect(versions[:draft]).to_not be_nil
          expect(versions[:public]).to be_nil
        end

        it 'should include matching draft and public versions for a newly published item' do
          content.add a_content_item.to_hash
          content.publish a_content_item.to_hash, in: a_content_item.locale

          draft_item = content.get_draft(of: a_content_item.to_hash, in: a_content_item.locale)

          versions = draft_item[:versions]

          expect(versions[:draft]).to_not be_nil
          expect(versions[:public]).to_not be_nil
          expect(versions[:draft]).to eq versions[:public]
        end
      end
    end

  end

end
