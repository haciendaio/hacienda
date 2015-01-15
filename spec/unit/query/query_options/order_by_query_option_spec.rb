require_relative '../../unit_helper'
require_relative '../../../../app/query/query_options/order_by_query_option'

module Hacienda
  module Test

    describe OrderByQueryOption do

      it 'should sort dates in descending order' do
        result = OrderByQueryOption.new('date desc').apply([{date: '01/01/2010'}, {date: '01/01/2011'}])

        expect(result.first[:date]).to eq('01/01/2011')
        expect(result.last[:date]).to eq('01/01/2010')
      end

      it 'should sort dates in ascending order' do
        result = OrderByQueryOption.new('date asc').apply([{date: '01/01/2011'}, {date: '01/01/2010'}])

        expect(result.first[:date]).to eq('01/01/2010')
        expect(result.last[:date]).to eq('01/01/2011')
      end

    end

  end
end
