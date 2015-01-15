require_relative 'generic_filter_query'

module Hacienda

  class ToLowerFilterQuery < GenericFilterQuery

    def initialize(parser)
      super(parser)
    end

    def is_satisfied_by?(content)
      @query_expression.accepts(content[@query_expression.fieldname].to_s.downcase)
    end

  end
end
