require_relative '../../unit_helper'
require_relative '../../../../app/query/query_options/filter_query_option'

module Hacienda
  module Test
    describe FilterQueryOption do

      let(:filter_factory) { double('filter_factory') }
      let(:filter_1) { double('filter', :is_satisfied_by? => true) }
      let(:filter_2) { double('filter', :is_satisfied_by? => true) }

      let(:content_items) { [ { content: '"Hello"'} ] }

      it 'should apply each filter against a piece of content' do
        content_items =  [ { content: '"Hello"'} ]
        query_option = 'filter_1 and filter_2'

        filter_factory.stub(:get_individual_filter).with('filter_1').and_return(filter_1)
        filter_factory.stub(:get_individual_filter).with('filter_2').and_return(filter_2)

        filters = FilterQueryOption.new(query_option, filter_factory)

        filters.apply(content_items)

        expect(filter_1).to have_received(:is_satisfied_by?).with({ content: '"Hello"'})
        expect(filter_2).to have_received(:is_satisfied_by?).with({ content: '"Hello"'})

      end

      context 'has an and' do
        it 'should keep the content items that satisfy all filters' do
          content_items =  [ { content: '"Hello"'} ]
          query_option = 'a_true_filter and another_true_filter'

          true_filter = double('filter', is_satisfied_by?: true)

          filter_factory.stub(:get_individual_filter).with('a_true_filter').and_return(true_filter)
          filter_factory.stub(:get_individual_filter).with('another_true_filter').and_return(true_filter)

          filters = FilterQueryOption.new(query_option, filter_factory)

          filtered_content_items = filters.apply(content_items)

          expect(filtered_content_items.size).to eq 1
        end

        it 'should filter out the content items that fail one of the filters' do
          content_items =  [ { content: '"Hello"'} ]
          query_option = 'true_filter and false_filter'

          true_filter = double('filter', is_satisfied_by?: true)
          false_filter = double('filter', is_satisfied_by?: false)

          filter_factory.stub(:get_individual_filter).with('true_filter').and_return(true_filter)
          filter_factory.stub(:get_individual_filter).with('false_filter').and_return(false_filter)

          filters = FilterQueryOption.new(query_option, filter_factory)

          filtered_content_items = filters.apply(content_items)

          expect(filtered_content_items.size).to eq 0
        end
      end

      context 'has an or' do
        it 'should keep the content items that satisfy one of filters' do
          content_items =  [ { content: '"Hello"'} ]
          query_option = 'true_filter or false_filter'

          true_filter = double('filter', is_satisfied_by?: true)
          false_filter = double('filter', is_satisfied_by?: false)

          filter_factory.stub(:get_individual_filter).with('true_filter').and_return(true_filter)
          filter_factory.stub(:get_individual_filter).with('false_filter').and_return(false_filter)

          filters = FilterQueryOption.new(query_option, filter_factory)

          filtered_content_items = filters.apply(content_items)

          expect(filtered_content_items.size).to eq 1
        end

        it 'should filter out the content items that satisfy one of filters' do
          content_items =  [ { content: '"Hello"'} ]
          query_option = 'false_filter or false_filter'

          false_filter = double('filter', is_satisfied_by?: false)

          filter_factory.stub(:get_individual_filter).with('true_filter').and_return(false_filter)
          filter_factory.stub(:get_individual_filter).with('false_filter').and_return(false_filter)

          filters = FilterQueryOption.new(query_option, filter_factory)

          filtered_content_items = filters.apply(content_items)

          expect(filtered_content_items.size).to eq 0
        end
      end

    end
  end
end