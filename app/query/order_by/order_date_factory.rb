require_relative 'order_date_descending'
require_relative 'order_date_ascending'

module Hacienda
  module OData

    REGEXP_MATCHING_FIELD_ORDER = /^(\S+)\s?(asc|desc)?$/

    class OrderDateFactory
      def initialize(expression_string)
        @expression_string = expression_string
      end

      def parse
        (order == 'desc') ? OrderDateDescending.new(field) : OrderDateAscending.new(field)
      end

      private

      def parse_expression
        REGEXP_MATCHING_FIELD_ORDER.match(@expression_string)
      end

      def field
        parse_expression[1].to_sym
      end

      def order
        parse_expression[2]
      end

    end
  end
end
