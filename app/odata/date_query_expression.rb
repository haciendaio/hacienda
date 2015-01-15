require_relative '../odata/operator'
require_relative '../odata/generic_query_expression'

module Hacienda

  module OData

    class DateQueryExpression < GenericQueryExpression

      attr_reader :fieldname

      def initialize(field, value, operator)
        super(field, value, operator)
        @query_value = Date.strptime(value)
      end
    end
  end
end