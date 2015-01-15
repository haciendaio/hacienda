require_relative 'generic_filter_query'

module Hacienda

  class DateFilterQuery < GenericFilterQuery

    def initialize(parser)
      super(parser)
    end

    def is_satisfied_by?(content)
      @query_expression.accepts(get_date(content[@query_expression.fieldname]))
    end

    private
    def get_date(date_string_representation)
      if (date_string_representation.include?('/'))
        Date.strptime(date_string_representation, '%d/%m/%Y')
      else
        Date.strptime(date_string_representation, '%Y-%m-%dT%T%:z')
      end
    end

  end
end
