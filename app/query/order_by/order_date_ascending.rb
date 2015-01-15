require_relative '../../exceptions/invalid_query_string_error'

module Hacienda
  module OData

    class OrderDateAscending

      def initialize(field)
        @fieldname = field
      end

      def sort(content)
        begin
          content.sort_by { |item| Date.parse(item[@fieldname]) }
        rescue StandardError
          raise Errors::InvalidQueryStringError.new('Order by field is not a date')
        end

      end

    end

  end
end