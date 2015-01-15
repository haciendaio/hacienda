require_relative '../unit_helper'
require_relative '../../../app/odata/operator'

module Hacienda
  module OData

    module Test
      describe Operator do

        OPERATOR_MAPPING= {'gt' => :>, 'ge' => :>=, 'eq' => :==, 'le' => :<=, 'lt' => :<}

        it 'should map to the correct symbol' do
          OPERATOR_MAPPING.each do | key, value |
            operator = Operator.new(key)
            expect(operator.comparison_method).to (eq value),"expected #{key} to map to #{value}, but got #{operator.comparison_method}"
          end
        end

      end

    end
  end
end
