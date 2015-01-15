require_relative 'operator'

module Hacienda
  module OData
    class GenericQueryExpression

      attr_reader :fieldname

      def initialize(fieldname, query_value, operator)
        @fieldname = fieldname
        @query_value = query_value
        @operator = operator
      end

      def accepts(field_value)
        field_value.send(@operator.comparison_method, @query_value)
      end

    end
  end
end