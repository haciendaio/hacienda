require_relative '../unit_helper'
require_relative '../../../app/odata/date_query_parser'
require_relative '../../../app/odata/generic_query_parser'
require_relative '../../../app/odata/generic_query_expression'

module Hacienda
  module OData
    module Test

      describe GenericQueryParser do

        let (:query_expression) { GenericQueryParser.new("cities eq 'new york'").parse }

        it 'should pull out the query value' do
          expect(query_expression.instance_variable_get(:@query_value)).to eq 'new york'
        end

        it 'should pull out the field' do
          expect(query_expression.instance_variable_get(:@fieldname)).to eq :cities
        end

        it 'should pull out the operator' do
          expect(query_expression.instance_variable_get(:@operator)).to be_kind_of Operator
        end

        it 'should return a Generic query expression' do
          expect(GenericQueryParser.new("cities eq 'new york'").parse).to be_kind_of GenericQueryExpression
        end

        it 'should return an invalid query string error if parsing fails' do
          expect{GenericQueryParser.new("anything not parsable'").parse}.to raise_error Errors::InvalidQueryStringError
        end

      end
    end
  end
end
