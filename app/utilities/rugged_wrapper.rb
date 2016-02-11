require 'rugged'

module Hacienda
  
  class RuggedWrapperFactory

    include Rugged

    def get_repo(repo_path)
      RuggedWrapper.new(repo_path, 
                        lambda{|path| Repository.new(path)},
                        lambda{|repo| Rugged::Walker.new(repo)})
    end

  end

  class RuggedWrapper

    include Rugged

    def initialize(repo_path, create_repo, create_walker)
      @repo_path = repo_path
      @create_repo = create_repo
      @create_walker = create_walker
    end
    
    def get_repo
      @repo ||= @create_repo[@repo_path]
      result = yield(@repo)
      @repo.close
      return result
    end

    def get_wrapper_for_repo repo
      @walker ||= @create_walker[repo]
    end

    def sha_for(item_path)
      get_repo do |repo| 
        next repo.head.target.tree.path(item_path)[:oid]
      end
    end

    def get_version_in_past(file_path, changes_in_the_past)
      raise ArgumentError if changes_in_the_past < 0

      get_repo do |repo|  
        walker = get_wrapper_for_repo(repo)
        walker.push(repo.last_commit)

        last_blob = repo.blob_at(repo.last_commit.oid, file_path)
        current_blob_id = last_blob.oid

        walker.each do |commit|
          blob = repo.blob_at(commit.oid, file_path)
          blob_id = (blob ? blob.oid : 0)

          if current_blob_id != blob_id
            current_blob_id = blob_id
            last_blob = blob
            changes_in_the_past -= 1
          end
          break if (changes_in_the_past == 0)
          break unless last_blob
        end
        next changes_in_the_past == 0 ? last_blob : nil
      end
    end
  end

end
