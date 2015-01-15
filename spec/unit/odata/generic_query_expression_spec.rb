require_relative '../unit_helper'
require_relative '../../../app/odata/generic_query_expression'

module Hacienda
  module OData

    module Test

      describe 'Generic Query Expression' do

        it 'should return the field' do
          query_expression = GenericQueryExpression.new(:any_field, '2014-03-30', Operator.new('lt'))

          expect(query_expression.fieldname).to eq :any_field
        end

        it 'should accept data which passes the query expression test' do
          generic_field_string = 'whatever'
          query_expression = GenericQueryExpression.new(:fieldname, generic_field_string, Operator.new('eq'))

          expect(query_expression.accepts('whatever')).to be_true
        end

        it 'should not accept data which does not pass the query expression test' do
          generic_unaccepted_field_string = 'something'
          query_expression = GenericQueryExpression.new(:fieldname, generic_unaccepted_field_string, Operator.new('eq'))

          expect(query_expression.accepts('not-in-there')).to be_false
        end

      end
    end
  end
end
