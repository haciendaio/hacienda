module Hacienda
  module OData

    class TopQueryExpression
      def initialize(number)
        @number = number
      end

      def top(array_of_items)
        array_of_items.take(@number)
      end
    end

  end
end
