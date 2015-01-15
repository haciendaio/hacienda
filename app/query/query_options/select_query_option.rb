module Hacienda
  class SelectQueryOption
    def initialize(query_option_value)
      @query_option_value = query_option_value
    end

    def apply(content)
      items = []

      content.each do |content_item|
        items << content_item[@query_option_value.to_sym]
      end

      items
    end
  end
end