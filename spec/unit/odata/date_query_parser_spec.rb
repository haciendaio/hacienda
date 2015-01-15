require_relative '../unit_helper'
require_relative '../../../app/odata/date_query_parser'

module Hacienda
  module OData
    module Test

      describe DateQueryParser do

        let (:query_expression) { DateQueryParser.new("date gt datetime'2014-01-23'").parse }

        it 'should pull out the date' do
          expect(query_expression.instance_variable_get(:@query_value)).to eq Date.strptime('2014-01-23')
        end

        it 'should pull out the field' do
          expect(query_expression.instance_variable_get(:@fieldname)).to eq :date
        end

        it 'should pull out the operator' do
          expect(query_expression.instance_variable_get(:@operator)).to be_kind_of Operator
        end

        it 'should return an invalid query string error if parsing fails' do
          expect{DateQueryParser.new("anything not parsable'").parse}.to raise_error Errors::InvalidQueryStringError
        end

      end
    end
  end
end
