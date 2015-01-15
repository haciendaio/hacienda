require_relative '../unit_helper'
require_relative '../../../app/odata/date_query_expression'

module Hacienda
  module OData

    module Test

      describe 'Date Query Expression' do

        it 'should return the field' do
          query_expression = DateQueryExpression.new(:fieldname, '2014-03-30', Operator.new('lt'))

          expect(query_expression.fieldname).to eq :fieldname
        end

        it 'should accept data which passes the query expression test' do
          date_string = '2014-03-30'
          query_expression = DateQueryExpression.new(:fieldname, date_string, Operator.new('lt'))

          expect(query_expression.accepts(Date.new(2014, 02, 28))).to be_true
        end

        it 'should not accept data which does not pass the query expression test' do
          date_string = '2014-03-30'
          query_expression = DateQueryExpression.new(:fieldname, date_string, Operator.new('lt'))

          expect(query_expression.accepts(Date.new(2014, 04, 28))).to be_false
        end

      end
    end
  end
end