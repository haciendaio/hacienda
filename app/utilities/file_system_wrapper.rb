module Hacienda
  class FileSystemWrapper

    def glob(pattern)
      Dir.glob(pattern)
    end

    def read(file_path)
      IO.read(file_path)
    end

    def basename(filename)
      File.basename(filename)
    end

    def extname(path)
      File.extname(path)
    end

    def exists?(filename)
      File.exists?(filename)
    end

    def find_all_ids(data_dir, path)
      glob("#{data_dir}/#{path}/*.json").collect { |x| strip_path_and_extension(x) }
    end

    def strip_path_and_extension(filename)
      basename(filename).chomp(extname(filename))
    end

    def full_path_of_referenced_file(data_filename, filename)
      File.join(File.dirname(data_filename), filename)
    end

  end
end