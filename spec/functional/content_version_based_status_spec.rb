require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../shared/metadata_builder'
require_relative '../../spec/shared/navigation'
require_relative '../../spec/functional/support/fake_github'

module Hacienda
  module Test

    describe 'version based status of items through the workflow' do
      include Navigation

      before :each do
        app.set :content_directory_path, TEST_REPO
        allow_any_instance_of(app).to receive(:github).and_return(FakeGithub.new(TEST_REPO))
      end

      let(:a_content_item) { ContentItem.new }
      let(:content) { Content.new }

      it 'should return nil version for both draft and public for content that has fallen back to another locale' do
        german_content = a_content_item.with locale: 'de'

        content.add german_content, in: 'de'

        english_translation = content.get_draft of: german_content, in: 'en'

        expect(draft_version(english_translation)).to be_nil
        expect(public_version(english_translation)).to be_nil

      end

      it 'should return not-nil draft version and nil public version for new content in the same locale' do
        german_content = a_content_item.with locale: 'de'

        content.add german_content, in: 'de'

        german_translation = content.get_draft of: german_content, in: 'de'

        expect(draft_version(german_translation)).not_to be_nil
        expect(public_version(german_translation)).to be_nil
      end

      it 'should return not-nil and different versions for public and draft when published item has been modified' do
        german_content = a_content_item.with locale: 'de'

        content.add german_content, in: 'de'
        content.publish german_content, in: 'de'
        content.update german_content.merge(some_content: 'changed'), in: 'de'
        german_translation = content.get_draft of: german_content, in: 'de'

        expect(draft_version(german_translation)).not_to be_nil
        expect(public_version(german_translation)).not_to be_nil
        expect(draft_version(german_translation)).not_to eq public_version(german_translation)
      end

      it 'should return not-nil and equal versions for public and draft when item has been published' do
        german_content = a_content_item.with locale: 'de'
        content.add german_content, in: 'de'
        content.publish german_content, in: 'de'

        german_translation = content.get_draft of: german_content, in: 'de'

        expect(draft_version(german_translation)).not_to be_nil
        expect(draft_version(german_translation)).to eq public_version(german_translation)
      end

      it 'should not have a versions field when retrieving public item' do
        german_content = a_content_item.with locale: 'de'
        content.add german_content, in: 'de'
        content.publish german_content, in: 'de'

        german_translation = content.get_public of: german_content, in: 'de'

        expect(german_translation[:versions]).to be_nil
      end

      def public_version(item)
        item[:versions][:public]
      end

      def draft_version(item)
        item[:versions][:draft]
      end

    end

  end

end

