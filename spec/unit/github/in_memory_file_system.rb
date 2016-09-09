require_relative '../../../app/github/git_file'

module Hacienda
  module Test

    class InMemoryFileSystem
      class TestFilesApi
        def initialize(files)
          @files = files
          @has_been_written_to = false
        end
        def setup(files)
          @files.merge! files
        end
        def exists?(path)
          @files.has_key? path
        end
        def content_of(path)
          @files[path]
        end
        def empty?
          @files.empty?
        end
        def sha_of(path)
          "sha of #{path}"
        end
        def has_been_written_to=(has)
          @has_been_written_to = has
        end
        def has_been_written_to?
          @has_been_written_to
        end
      end

      def initialize
        @files = {}
      end
      def content_exists?(path)
        @files.has_key? path
      end
      def get_content(path)
        stored_file(path)
      end

      def write_files(description, files)
        test_api.has_been_written_to = true
        @files.merge! files
        stored_files = files.each_pair.map do |path, content|
          [path, stored_file(path)]
        end.to_h
        stored_files
      end

      def test_api
        TestFilesApi.new(@files)
      end

      private

      def stored_file(path)
        GitFile.new @files[path], path, test_api.sha_of(path)
      end
    end

  end
end

