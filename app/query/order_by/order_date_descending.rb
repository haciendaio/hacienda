require_relative 'order_date_ascending'

module Hacienda
  module OData

    class OrderDateDescending < OrderDateAscending

      def initialize(field)
        super(field)
      end

      def sort(content)
        super(content).reverse
      end

    end
  end

end