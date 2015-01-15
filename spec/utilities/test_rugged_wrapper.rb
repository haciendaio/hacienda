module Hacienda
  module Test

    class TestRuggedWrapper < RuggedWrapper

      def initialize(repo_path)
        super(repo_path)
      end

      def self.init_git_repo(repo_path)
        repo = Repository.init_at(repo_path)

        oid = repo.write('some initial stuff', :blob)
        index = repo.index

        index.add(:path => 'readme', :oid => oid, :mode => 0100644)

        options = {}
        options[:tree] = index.write_tree(repo)

        options[:author] = {:email => 'testuser@github.com', :name => 'Test Author', :time => Time.now}
        options[:committer] = {:email => 'testuser@github.com', :name => 'Test Author', :time => Time.now}
        options[:message] ||= 'Setting up for test'
        options[:parents] = repo.empty? ? [] : [repo.head.target].compact
        options[:update_ref] = 'HEAD'

        Rugged::Commit.create(repo, options)
      end

      def commit(content, path)
        oid = @repo.write(content, :blob)
        index = @repo.index
        index.read_tree(@repo.head.target.tree)
        index.add(:path => path, :oid => oid, :mode => 0100644)

        options = {}
        options[:tree] = index.write_tree(@repo)

        options[:author] = {:email => 'testuser@github.com', :name => 'Test Author', :time => Time.now}
        options[:committer] = {:email => 'testuser@github.com', :name => 'Test Author', :time => Time.now}
        options[:message] ||= 'Setting up for test'
        options[:parents] = @repo.empty? ? [] : [@repo.head.target].compact
        options[:update_ref] = 'HEAD'

        Rugged::Commit.create(@repo, options)
      end
    end
  end
end