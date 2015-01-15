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


    end
  end
end