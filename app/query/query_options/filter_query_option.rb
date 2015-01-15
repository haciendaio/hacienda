require_relative '../../filters/date_filter_query'
require_relative '../../filters/generic_filter_query'
require_relative '../../odata/date_query_parser'
require_relative '../../odata/generic_query_parser'
require_relative '../../query/filter/filter_factory'

module Hacienda

  class FilterQueryOption

    def initialize(query_option_value, filter_factory = FilterFactory.new)
      @filter_factory = filter_factory
      @query_option_value = query_option_value
    end

    def apply(content_items)
      queries = extract_queries

      content_items.find_all do |content_item|
        queries.all? { |query| query.is_satisfied_by?(content_item) }
      end

    end

    private

    def extract_queries
      query_items = @query_option_value.split(/\s(and)\s/)
      queries = query_items.select.each_with_index { |str, i| i.even? }
      return queries.collect { |query| @filter_factory.get_individual_filter(query) }
    end

  end
end
