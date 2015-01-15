module Hacienda

  class GenericFilterQuery
    def initialize(parser)
      @query_expression = parser.parse
    end

    def is_satisfied_by?(content)
      @query_expression.accepts(content[@query_expression.fieldname])
    end
  end

end

