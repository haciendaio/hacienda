require_relative '../unit_helper'
require_relative '../../../app/odata/top_query_parser'
require_relative '../../../app/exceptions/invalid_query_string_error'

module Hacienda
  module OData
    module Test

      describe 'Top query parser' do

        it 'should pull out the number' do
          five_as_string = '5'
          top_query_expression = TopQueryParser.new(five_as_string).parse
          expect(top_query_expression.instance_variable_get(:@number)).to eq 5
        end

        it 'should return a query exception when provided a non-number' do
          some_string = 'blah'
          expect{ TopQueryParser.new(some_string).parse }.to raise_error Errors::InvalidQueryStringError
        end

        it 'should return a query exception when provided a negative number' do
          some_string = '-1'
          expect{ TopQueryParser.new(some_string).parse }.to raise_error Errors::InvalidQueryStringError
        end

        it 'should return a query exception when provided a non-integer' do
          some_string = '1.4'
          expect{ TopQueryParser.new(some_string).parse }.to raise_error Errors::InvalidQueryStringError
        end

      end

    end
  end
end
