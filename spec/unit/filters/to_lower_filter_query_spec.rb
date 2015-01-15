require_relative '../unit_helper'
require_relative '../../../app/filters/to_lower_filter_query'
require_relative '../../../app/odata/to_lower_query_parser'

module Hacienda
  module Test

    describe ToLowerFilterQuery do

      it 'should match the query for toggled case in type' do
        content =  {id: 'a', hair: 'BLonde'}

        filter_expression = "tolower(hair) eq 'blonde'"
        filter = ToLowerFilterQuery.new(OData::ToLowerQueryParser.new(filter_expression))

        expect(filter.is_satisfied_by?(content)).to be_true

      end

      it 'should match the query for toggled case in queried value' do
        content =  {id: 'a', hair: 'BLonde'}

        filter_expression = "tolower(hair) eq 'bLONde'"
        filter = ToLowerFilterQuery.new(OData::ToLowerQueryParser.new(filter_expression))

        expect(filter.is_satisfied_by?(content)).to be_true

      end
    end

  end
end