require_relative '../../../app/filters/top_query'
require_relative '../unit_helper'

module Hacienda
  module Test
    describe 'Top Query' do

      it 'should return only the top elements in the array' do
        item_a = {id: 'a', something: 'a data'}
        item_b = {id: 'b', something: 'b data'}
        item_c = {id: 'c', something: 'c data'}

        content = [item_a, item_b, item_c]

        top_listed_content = [item_a]

        top_query_expression = double('TopQueryExpression', :top => top_listed_content)
        query_parser = double('TopQueryParser', :parse =>  top_query_expression)

        top_query = TopQuery.new(query_parser)

        expect(top_query.query(content)).to eq top_listed_content
        expect(top_query_expression).to have_received(:top).with(content)
      end


    end
  end
end