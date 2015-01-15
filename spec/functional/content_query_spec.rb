require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../shared/metadata_builder'
require_relative '../../spec/shared/navigation'

module Hacienda
  module Test
    describe 'Generic query content' do
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

      it 'should return latest n items' do
        newest_content_item = {id: 'lemon1', date: '25/01/2014'}
        second_newest_content_item = {id: 'lemon2', date: '20/01/2014'}
        third_newest_content_item = {id: 'lemon3', date: '05/11/2010'}

        test_content_manager.add_item('public', 'en', 'fruit', 'lemon1', newest_content_item, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'lemon2', second_newest_content_item, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'lemon3', third_newest_content_item, default_metadata)

        latest_2_items = get_public_items('fruit', 'en', '$top=2&$orderBy=date')

        expect(latest_2_items[0]).to include third_newest_content_item
        expect(latest_2_items[1]).to include second_newest_content_item
      end

      it 'should return the top 2 events, filtered by location and ordered by date' do
        one = {city: 'manchester', date:'17/02/2015', id:'manchester-event'}
        two = {city: 'manchester', date:'18/02/2015', id:'manchester-event-new'}

        three = {city: 'london', date:'12/12/2014', id:'london-event'}
        four = {city: 'london', date:'17/08/2014', id:'some-london-event'}
        five = {city: 'london', date:'07/07/2014', id:'another-london-event'}
        six = {city: 'london', date:'07/07/2013', id:'yet-another-london-event'}

        test_content_manager.add_item('public', 'en', 'fruit', 'manchester-event', one, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'manchester-event-new', two, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'london-event', three, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'some-london-event', four, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'another-london-event', five, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'yet-another-london-event', six, default_metadata)

        top_2_events_for_london = get_public_items('fruit', 'en', "$filter=date gt datetime'2014-01-01' and city eq 'london'&$orderBy=date desc&$top=2")

        expect(top_2_events_for_london.first).to include three
        expect(top_2_events_for_london.last).to include four
      end

      it 'should return the top 1 events, filtered by location and ordered by date' do
        one = {city: 'manchester', date:'17/02/2015', id:'manchester-event'}
        two = {city: 'manchester', date:'18/02/2015', id:'manchester-event-new'}

        three = {city: 'london', date:'12/12/2014', id:'london-event'}
        four = {city: 'london', date:'17/08/2014', id:'some-london-event'}
        five = {city: 'london', date:'07/07/2014', id:'another-london-event'}
        six = {city: 'london', date:'07/07/2013', id:'yet-another-london-event'}

        test_content_manager.add_item('public', 'en', 'fruit', 'manchester-event', one, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'manchester-event-new', two, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'london-event', three, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'some-london-event', four, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'another-london-event', five, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'yet-another-london-event', six, default_metadata)


        top_event_for_london = get_public_items('fruit', 'en', "$filter=date gt datetime'2014-01-01' and city eq 'london' and id eq 'london-event'&$orderBy=date desc&$top=2")

        expect(top_event_for_london.first).to include three
      end

      it 'should return fruit by case-insensitive type - i.e. using tolower' do

        test_content_manager.add_item('public', 'en', 'fruit', 'apple', {type: 'Apple', id:'apple'}, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'apple-mixed', {type: 'APPle', id:'apple-mixed'}, default_metadata)
        test_content_manager.add_item('public', 'en', 'fruit', 'banana', {type: 'banana', id:'banana'}, default_metadata)

        fruit = get_public_items('fruit', 'en', "$filter=tolower(type) eq 'apple'")

        fruit_ids = fruit.collect { |f| f[:id] }

        expect(fruit_ids).to match_array %w(apple apple-mixed)
      end


    end
  end
end
