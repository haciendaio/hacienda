require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../shared/metadata_builder'
require_relative '../../spec/shared/navigation'
require_relative '../../spec/functional/support/fake_github_file_system'
require_relative '../shared/content_item'

module Hacienda
  module Test

    describe 'deleting items' do
      include Navigation

      let(:fake_github) { FakeGithubFileSystem.new(TEST_REPO) }
      let(:a_content_item) { ContentItem.new }
      let(:content) { Content.new }

      before :each do
        app.set :content_directory_path, TEST_REPO
        allow_any_instance_of(app).to receive(:github_file_system).and_return(fake_github)
      end

      it 'should delete all content for a specific item' do

        content_item = a_content_item.with locale: 'en'

        content.add content_item
        content.update content_item, in: 'de'
        content.update content_item, in: 'es'

        expect(fake_github.size).to eq 4

        content.delete content_item

        expect(fake_github.size).to eq 0

        expect { content.get_draft of: content_item, in: 'en' }.to raise_error Hacienda::Errors::ResourceNotFoundError
        expect { content.get_draft of: content_item, in: 'de' }.to raise_error Hacienda::Errors::ResourceNotFoundError
        expect { content.get_draft of: content_item, in: 'es' }.to raise_error Hacienda::Errors::ResourceNotFoundError

      end

    end

  end

end

