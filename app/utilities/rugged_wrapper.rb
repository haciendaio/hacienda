require 'rugged'

module Hacienda

  class RuggedWrapperFactory

    def get_repo(repo_path)
      RuggedWrapper.new(repo_path)
    end

  end

  class RuggedWrapper

    include Rugged

    def initialize(repo_path)
      @repo = Repository.new(repo_path)
    end

    def sha_for(item_path)
      @repo.head.target.tree.path(item_path)[:oid]
    end

  end

end
