require_relative '../unit_helper'
require_relative '../../../app/filters/field_filter_query'

module Hacienda

  module Test
    describe 'Field filter' do

      it 'should pass through all fields in the list of fields' do
        requested_fields = [:id, :title, :content]
        content = {id: 'someid', title: 'some title', content: 'some content'}

        field_filter = FieldFilterQuery.new(requested_fields)

        expect(field_filter.query(content)).to eq content
      end

      it 'should only return the fields in the list' do
        requested_fields = [:id, :title]
        content = {id: 'hi', title: 'there', stuff: 'nonsense'}

        field_filter = FieldFilterQuery.new(requested_fields)
        filtered_content = field_filter.query(content)

        expect(filtered_content.keys).to eq [:id, :title]
      end

      it 'should filter arrays as well as single content items' do
        requested_fields = [:id, :title]
        content = [{id: 'hi', title: 'there', stuff: 'nonsense'}, {id: 'thing', title: 'title', stuff: 'bing'}]

        field_filter = FieldFilterQuery.new(requested_fields)
        filtered_content = field_filter.query(content)

        expect(filtered_content.size).to eq 2
        filtered_content.each do |item|
          expect(item.keys).to eq [:id, :title]
        end

      end
    end

  end

end
