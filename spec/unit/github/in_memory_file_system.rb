require_relative '../../../app/github/git_file'

module Hacienda
  module Test

    class InMemoryFileSystem
      class TestFilesApi
        def initialize(files)
          @files = files
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

