module Hacienda

  class TopQuery

    def initialize(parser)
      @top_query_expression = parser.parse
    end

    def query(content)
      @top_query_expression.top(content)
    end
  end
end