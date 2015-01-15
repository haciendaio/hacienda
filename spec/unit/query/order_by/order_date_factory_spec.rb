require_relative '../../unit_helper'
require_relative '../../../../app/odata/operator'
require_relative '../../../../app/exceptions/invalid_query_string_error'
require_relative '../../../../app/query/order_by/order_date_factory'

module Hacienda
  module OData
    module Test

      describe OrderDateFactory do

        it 'should parse a simple orderby query with default ordering ascending' do
          simple_order_by_query = 'date'
          order_by_query_expression = OrderDateFactory.new(simple_order_by_query).parse
          expect(order_by_query_expression).to be_a OrderDateAscending
          expect(order_by_query_expression.instance_variable_get(:@fieldname)).to eq(:date)
        end

        it 'should parse orderby with asc' do
          simple_order_by_query = 'date asc'
          order_by_query_expression = OrderDateFactory.new(simple_order_by_query).parse
          expect(order_by_query_expression).to be_a OrderDateAscending
          expect(order_by_query_expression.instance_variable_get(:@fieldname)).to eq(:date)
        end

        it 'should parse orderby with desc' do
          simple_order_by_query = 'date desc'
          order_by_query_expression = OrderDateFactory.new(simple_order_by_query).parse
          expect(order_by_query_expression).to be_a OrderDateDescending
          expect(order_by_query_expression.instance_variable_get(:@fieldname)).to eq(:date)
        end

      end

      describe 'Order ascending' do

        it 'should sort an array of hashes by the given date field' do
          list_of_hashes = [ {date: '25/06/1980', id: 'first'}, {date: '30/10/1950', id: 'second'} ]
          sorted_list = OrderDateAscending.new(:date).sort(list_of_hashes)

          expect(sorted_list).to eq [ {date: '30/10/1950', id: 'second'}, {date: '25/06/1980', id: 'first'}]
        end

        it 'should throw an Invalid query string error when the field does not exist' do
          list_of_hashes = [ {spinach: '25/06/1980', id: 'first'}, {spinach: '30/10/1950', id: 'second'} ]

          expect { OrderDateAscending.new(:date).sort(list_of_hashes) }.to raise_error Errors::InvalidQueryStringError
        end

      end

      describe 'Order descending' do

        it 'should sort an array of hashes by the given date field' do
          list_of_hashes = [ {date: '25/06/1980', id: 'first'}, {date: '30/10/1950', id: 'second'} ]
          sorted_list = OrderDateDescending.new(:date).sort(list_of_hashes)

          expect(sorted_list).to eq [{date: '25/06/1980', id: 'first'}, {date: '30/10/1950', id: 'second'}]
        end

        it 'should throw an Invalid query string error when the field does not exist' do
          list_of_hashes = [ {spinach: '25/06/1980', id: 'first'}, {spinach: '30/10/1950', id: 'second'} ]

          expect { OrderDateDescending.new(:date).sort(list_of_hashes) }.to raise_error Errors::InvalidQueryStringError
        end

      end

    end
  end
end
