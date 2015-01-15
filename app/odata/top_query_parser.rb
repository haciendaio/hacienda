require_relative 'top_query_expression'
module Hacienda
  module OData
    class TopQueryParser

      def initialize(expression_string)
        @expression_string = expression_string
      end

      def parse
        begin
          TopQueryExpression.new(positive_number)
        rescue ArgumentError => ex
          raise Errors::InvalidQueryStringError, ex.message
        end
      end

      private

      def positive_number
        number = Integer(@expression_string)
        if number<=0
          raise ArgumentError,'Number should be positive'
        end
        number
      end

    end
  end
end
