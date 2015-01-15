require_relative '../exceptions/invalid_query_string_error'
require_relative 'generic_query_expression'

module Hacienda
  module OData

    class GenericQueryParser

      def initialize(expression_string)
        @expression_string = expression_string
      end

      def parse
        begin
          GenericQueryExpression.new(field, value, operator)
        rescue StandardError => ex
          raise Errors::InvalidQueryStringError, ex.message
        end
      end

      def parse_expression
        regular_expression = /^(\S+)\s(\S+)\s'(.+)'/
        regular_expression.match(@expression_string)
      end

      private

      def field
        parse_expression[1].to_sym
      end

      def operator
        Operator.new(parse_expression[2])
      end

      def value
        parse_expression[3]
      end

    end
  end
end
