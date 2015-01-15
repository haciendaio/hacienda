require_relative '../exceptions/invalid_query_string_error'
require_relative 'generic_query_expression'
require_relative 'generic_query_parser'

module Hacienda
  module OData

    class ToLowerQueryParser < GenericQueryParser

      def initialize(expression_string)
        super(expression_string)
      end

      def parse_expression
        regular_expression = /^tolower\((\S+)\)\s(\S+)\s'(.+)'/
        regular_expression.match(@expression_string)
      end

      private

      def value
        parse_expression[3].to_s.downcase
      end

    end
  end
end
