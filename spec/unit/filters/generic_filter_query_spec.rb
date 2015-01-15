require_relative '../unit_helper'
require_relative '../../../app/filters/generic_filter_query'
require_relative '../../../app/odata/generic_query_parser'

module Hacienda
  module Test

    describe GenericFilterQuery do

      it 'should match the generic query' do
        content = {id: 'a', potato: 'old-potato'}
        filter_expression = "potato eq 'old-potato'"
        filter = GenericFilterQuery.new(OData::GenericQueryParser.new(filter_expression))

        expect(filter.is_satisfied_by?(content)).to be_true
      end

      it 'should not match the query' do
        content = {id: 'a', thing: '123'}

        filter_string = "thing eq '222'"
        filter = GenericFilterQuery.new(OData::GenericQueryParser.new(filter_string))

        expect(filter.is_satisfied_by?(content)).to be_false

      end

    end
  end
end
