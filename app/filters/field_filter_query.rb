module Hacienda

  class FieldFilterQuery
    def initialize(field_list)
      @field_list = field_list
    end

    def query(content)

      if content.is_a? Array
        return content.map { |item| query(item) }
      end

      content.keep_if { |key, value| @field_list.include?(key) }
    end
  end
end
