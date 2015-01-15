module Hacienda

  class ReferencedFile

    attr_accessor :key, :value

    def initialize(id, file_type, key, value)
      @id = id
      @value = value
      @key = key
      @file_type = file_type
    end

    def field_name
      key.chomp("_#{@file_type}")
    end

    def file_name
      "#{@id}-#{field_name}.#{@file_type}".gsub('_', '-')
    end

    def ref_name
      "#{field_name}_ref"
    end

  end

end

