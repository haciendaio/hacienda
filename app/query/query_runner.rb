require_relative '../query/query_options/filter_query_option'
require_relative '../query/query_options/order_by_query_option'
require_relative '../query/query_options/top_query_option'
require_relative '../query/query_options/select_query_option'

module Hacienda

  class QueryRunner

    def initialize(query_hash, query_options = QueryOptionLoader.load(query_hash))
      @query_hash = query_hash
      @query_options = query_options
    end

    def apply(content_items)
      modified_content_items = content_items.clone
      @query_options.each do |query_option|
        modified_content_items = query_option.apply(modified_content_items)
      end
      modified_content_items
    end

    class QueryOptionLoader

      @@ordered_query_parts = {
          '$filter' => lambda { |query_option_value| FilterQueryOption.new(query_option_value) },
          '$orderBy' => lambda { |query_option_value| OrderByQueryOption.new(query_option_value) },
          '$top' => lambda { |query_option_value| TopQueryOption.new(query_option_value) },
          '$select' => lambda { |query_option_value| SelectQueryOption.new(query_option_value) }
      }

      def self.load(query_hash)
        all_queries = []
        @@ordered_query_parts.each_pair { |query_name, query_option|
          all_queries << query_option.call(query_hash[query_name]) if query_hash.has_key? query_name
        }
        all_queries
      end

    end

  end

end