module Hacienda

  class ReferencedFileHandler

    def initialize(file_system_wrapper)
      @file_system_wrapper = file_system_wrapper
    end

    def can_handle?(key)
      key.to_s.end_with? '_ref'
    end

    def handle!(data, key, filename)
      absolute_path = @file_system_wrapper.full_path_of_referenced_file(filename, data[key])

      if @file_system_wrapper.exists?(absolute_path)
        file_extension = @file_system_wrapper.extname(absolute_path)
        data[generate_field_name(key, file_extension)] = @file_system_wrapper.read(absolute_path)
      end
    end

    private

    def generate_field_name(current_key, referenced_file_extension)
      replacement_suffix = referenced_file_extension.gsub('.', '_')
      current_key.to_s.gsub('_ref', replacement_suffix).to_sym
    end

  end

end