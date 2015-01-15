require_relative '../../unit_helper'
require_relative '../../../../app/query/filter/filter_factory'

module Hacienda
  module Test
    describe FilterFactory do

      it 'should extract a date filter from a string' do
        filter = "thing gt datetime'2014-01-01'"

        filter_factory = FilterFactory.new
        expect(filter_factory.get_individual_filter(filter)).to be_a DateFilterQuery
      end

      it 'should extract a generic filter from a string' do
        filter = "city eq 'london'"

        filter_factory = FilterFactory.new
        expect(filter_factory.get_individual_filter(filter)).to be_a GenericFilterQuery
      end

      it 'should extract a to lower filter from a string' do
        filter = "tolower(city) eq 'london'"

        filter_factory = FilterFactory.new
        expect(filter_factory.get_individual_filter(filter)).to be_a ToLowerFilterQuery
      end

    end

  end
end