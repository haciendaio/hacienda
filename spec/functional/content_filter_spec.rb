require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../../spec/shared/navigation'
require_relative '../shared/metadata_builder'

module Hacienda
  module Test

    describe 'Generic Content filters' do
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

      let(:test_content_manager) { TestContentManager.new(TEST_REPO) }
      let(:default_metadata) { MetadataBuilder.new.default.build }

      it 'should return all fields by default' do
        first_banana = {id: 'banana1', colour: 'Yellow', shape: 'bent'}
        test_content_manager.add_item('public', 'en', 'fruit', 'banana1', first_banana, default_metadata)

        items = get_public_items('fruit', 'en')
        expect(items[0].keys).to match_array [ :id, :colour, :shape, :translated_locale, :last_modified, :last_modified_by]
      end

      it 'should include items which match one of the filters in or' do
        content_item = {id: 'banana1', colour: 'Yellow', shape: 'bent', date: '25/01/2014'}
        blue_content_item = {id: 'banana2', colour: 'Blue', shape: 'bent', date: '25/01/2014'}
        test_content_manager.add_item('public', 'en', 'fruit', 'banana1', content_item, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'banana2', blue_content_item, default_metadata)

        items = get_public_items('fruit','en',"$filter=date gt datetime'2014-01-24' or tolower(colour) eq 'blue'")
        expect(items.first).to include content_item
        expect(items[1]).to include blue_content_item
      end

      it 'should not include items which do not match all the filters in and' do
        matched_content_item = {id: 'banana1', colour: 'Yellow', shape: 'bent', date: '25/01/2014'}
        unmatched_content_item = {id: 'apple', colour: 'Green', shape: 'round', date: '23/01/2014'}

        test_content_manager.add_item('public', 'en', 'fruit', 'banana1', matched_content_item, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'apple', unmatched_content_item, default_metadata)

        items = get_public_items('fruit','en',"$filter=date gt datetime'2014-01-24' and date lt datetime'2014-01-26'")
        expect(items.length).to be 1
      end

    end
  end
end
