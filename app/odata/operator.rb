module Hacienda
  module OData

    class Operator

      OPERATOR_MAPPING= { 'gt' => :>, 'ge' => :>=, 'eq' => :==, 'le' => :<=, 'lt' => :< }

      def initialize(odata_operator_string)
        @odata_operator_string = odata_operator_string
      end

      def comparison_method
        OPERATOR_MAPPING[@odata_operator_string]
      end

    end
  end
end
