require_relative '../../unit_helper'
require_relative '../../../../app/query/query_options/select_query_option'

module Hacienda
  module Test
    describe SelectQueryOption do
      it 'should select only the specified properties' do
        result = SelectQueryOption.new('id').apply([{id: 'an_id', stuff: 'do not care'}, {id: 'another_id', stuff: 'do not care'}])

        expect(result.size).to eq 2
        expect(result.first).to eq('an_id')
      end
    end
  end
end