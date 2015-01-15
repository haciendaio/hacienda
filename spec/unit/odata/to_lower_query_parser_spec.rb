require_relative '../unit_helper'
require_relative '../../../app/odata/date_query_parser'
require_relative '../../../app/odata/to_lower_query_parser'
require_relative '../../../app/odata/generic_query_expression'

module Hacienda
  module OData
    module Test

      describe ToLowerQueryParser do

        let (:query_expression) { ToLowerQueryParser.new("tolower(cities) eq 'new YOrk'").parse }

        it 'should pull out the query value in lowercase' do
          expect(query_expression.instance_variable_get(:@query_value)).to eq 'new york'
        end

        it 'should pull out the field' do
          expect(query_expression.instance_variable_get(:@fieldname)).to eq :cities
        end

        it 'should pull out the operator' do
          expect(query_expression.instance_variable_get(:@operator)).to be_kind_of Operator
        end

        it 'should return a Generic query expression' do
          expect(ToLowerQueryParser.new("tolower(cities) eq 'new YOrk'").parse).to be_kind_of GenericQueryExpression
        end

        it 'should return an invalid query string error if parsing fails' do
          expect{ToLowerQueryParser.new("anything not parsable'").parse}.to raise_error Errors::InvalidQueryStringError
        end

      end
    end
  end
end
