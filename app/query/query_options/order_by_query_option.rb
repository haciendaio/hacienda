require_relative '../../query/order_by/order_date_factory'

module Hacienda

  class OrderByQueryOption

    def initialize(query_option_value)
      @orderer = OData::OrderDateFactory.new(query_option_value).parse
    end

    def apply(content)
      @orderer.sort(content)
    end

  end

end
