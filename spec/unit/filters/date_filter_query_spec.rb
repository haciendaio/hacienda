require_relative '../unit_helper'
require_relative '../../../app/filters/date_filter_query'
require_relative '../../../app/odata/date_query_parser'

module Hacienda
  module Test

    describe 'Date filter Query' do

      it 'should match the query' do
        content =  {id: 'a', date: '25/01/2014'}

        filter_expression = "date gt datetime'2014-01-23'"
        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_expression))

        expect(filter.is_satisfied_by?(content)).to be_true
      end

      it 'should not match the query' do
        content = {id: 'a', date: '25/01/2014'}

        filter_string = "date gt datetime'2014-01-27'"
        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_string))

        expect(filter.is_satisfied_by?(content)).to be_false
      end

      it 'should be able to filter on the named field' do
        content = {id: 'a', thing: '28/01/2014'}

        filter_string = "thing gt datetime'2014-01-27'"
        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_string))

        expect(filter.is_satisfied_by?(content)).to be_true
      end

      it 'should be able to filter by datetime format and keep the items with dates since the filtered date' do
        content = {id: 'a', date: '2014-08-28T10:52:58+01:00'}

        filter_string = "date gt datetime'2014-01-27'"

        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_string))

        expect(filter.is_satisfied_by?(content)).to be_true
      end

      it 'should be able to filter datetime format and remove the items with dates before the filtered date' do
        content = {id: 'a', date: '2013-08-28T10:52:58+01:00'}

        filter_string = "date gt datetime'2014-01-27'"

        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_string))

        expect(filter.is_satisfied_by?(content)).to be_false
      end

      it 'should throw an ArgumentError when the format of the date is not a date or datetime' do
        content = {id: 'a', date: 'not-a-date-or-datetime'}

        filter_string = "date gt datetime'2014-01-27'"

        filter = DateFilterQuery.new(OData::DateQueryParser.new(filter_string))

        expect { filter.is_satisfied_by?(content) }.to raise_error(ArgumentError)
      end

    end
  end
end
