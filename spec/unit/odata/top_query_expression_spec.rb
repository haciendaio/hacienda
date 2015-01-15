require_relative '../unit_helper'
require_relative '../../../app/odata/top_query_expression'

module Hacienda
  module OData
    module Test

      describe 'Top query expression' do

        it 'should return the first n items from content' do

          top_query_expression = TopQueryExpression.new(2)
          items = ['a','b','c','d']
          top_2_items = ['a','b']

          expect(top_query_expression.top(items)).to eq top_2_items

        end
      end

    end
  end
end
