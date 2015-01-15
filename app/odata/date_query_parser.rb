require_relative '../odata/date_query_expression'
require_relative '../exceptions/invalid_query_string_error'
require_relative 'generic_query_parser'

module Hacienda
  module OData

    class DateQueryParser < GenericQueryParser

      def initialize(expression_string)
        super(expression_string)
      end

      def parse
        begin
          DateQueryExpression.new(field, value, operator)
        rescue StandardError => ex
          raise Errors::InvalidQueryStringError,ex.message
        end
      end

      def parse_expression
        regular_expression = /^(\S+)\s(\S+)\sdatetime'(.+)'/
        regular_expression.match(@expression_string)
      end

    end

  end
end
