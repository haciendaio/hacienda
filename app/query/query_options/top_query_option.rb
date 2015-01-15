require_relative '../../filters/top_query'
require_relative '../../odata/top_query_parser'

module Hacienda

  class TopQueryOption

    def initialize(query_option_value)
      parser = OData::TopQueryParser.new(query_option_value)
      @query = TopQuery.new(parser)
    end

    def apply(content)
      @query.query(content)
    end

  end

end