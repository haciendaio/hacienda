require_relative '../../../app/github/git_file'
require_relative '../../utilities/test_rugged_wrapper'
require 'fileutils'

module Hacienda
  module Test

    class FakeGithub

      def initialize(content_directory_path, log = false)
        @location = content_directory_path
        @log = log
        clean!
        TestRuggedWrapper.init_git_repo(content_directory_path)
      end

      def create_content(path, content, commit_message = '')
        log 'create_content', path
        open(full_path(path), 'w+') { |file| file.write content }

        git_wrapper = TestRuggedWrapper.new(@location)
        git_wrapper.commit(content, path)

        GitFile.new(content, path, generate_hash(path))
      end

      def delete_content(path, commit_message = '')
        log 'delete_content', path
        File.delete(full_path(path))
      end

      def get_content(path)
        log 'get_content', path
        content = File.read full_path(path)
        GitFile.new(content, path, generate_hash(path))
      end

      def content_exists?(path)
        log 'content_exists?', path
        File.exists? full_path(path)
      end

      # TEST HELPERS

      def size
        Dir.glob(File.join(@location, '**', '*')).select { |file| File.file?(file) }.count
      end

      private

      def full_path(path)
        ensure_path("#{@location}/#{path}")
      end

      def ensure_path(path)
        FileUtils.mkdir_p File.dirname(path)
        path
      end

      def clean!
        FileUtils.rm_rf @location
      end

      def log(message, path)
        puts "PATH: #{path}, ACTION: #{message}" if @log
      end

      def generate_hash(path)
        begin
          ShellExecutor.new.run("git hash-object #{full_path(path)}").chomp()
        rescue
          ''
        end
      end
    end
  end
end


