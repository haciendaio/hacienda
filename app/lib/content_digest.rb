require_relative '../utilities/file_system_wrapper'
require_relative '../utilities/rugged_wrapper'

module Hacienda
  class ContentDigest

    def initialize(repo_path, executor, file_system_wrapper, git_wrapper_factory = RuggedWrapperFactory.new)
      @executor = executor
      @file_system_wrapper = file_system_wrapper
      @repo_path = repo_path
      @git_wrapper_factory = git_wrapper_factory
    end

    def get_sha_for(item_path)
      file_path = "#{@repo_path}/#{item_path}"

      if @file_system_wrapper.exists? file_path
        git_wrapper.sha_for(item_path)
      else
        ''
      end
    end

    def item_version(path1, path2)
     first_sha = get_sha_for(path1)
     second_sha = get_sha_for(path2)

     return nil if first_sha + second_sha == ''

     generate_digest([first_sha, second_sha])
    end

    def generate_digest(shas)
      combined_shas = shas.inject(:+)
      Digest::SHA2.new.update(combined_shas).to_s
    end

    private

    def git_wrapper
      @git_wrapper ||= @git_wrapper_factory.get_repo(@repo_path)
    end

  end
end
