require_relative '../../filters/date_filter_query'
require_relative '../../filters/generic_filter_query'
require_relative '../../filters/to_lower_filter_query'
require_relative '../../odata/generic_query_parser'
require_relative '../../odata/to_lower_query_parser'
require_relative '../../odata/date_query_parser'

module Hacienda

  class FilterFactory
    def get_individual_filter(query_option_value)
      if query_option_value.include? 'datetime'
        parser = OData::DateQueryParser.new(query_option_value)
        DateFilterQuery.new(parser)
      elsif query_option_value.include? 'tolower'
        parser = OData::ToLowerQueryParser.new(query_option_value)
        ToLowerFilterQuery.new(parser)
      else
        parser = OData::GenericQueryParser.new(query_option_value)
        GenericFilterQuery.new(parser)
      end
    end
  end

end