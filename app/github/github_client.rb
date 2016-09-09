require_relative 'github_settings'

module Hacienda


  class GithubClient
    include GithubSettings

    def initialize(settings, octokit_client = authenticated_octokit_client)
      @octokit_client = octokit_client
      @settings = settings
    end

    def get_head_reference
      @octokit_client.ref(content_repo, 'heads/master').object.sha
    end

    def create_blob(content)
      @octokit_client.create_blob(content_repo, Base64.strict_encode64(content), 'base64')
    end

    def get_tree(head_reference)
      @octokit_client.commit(content_repo, head_reference).commit.tree.sha
    end

    def update_tree(base_tree, new_tree)
      @oktokit_client.create_tree(content_repo, new_tree, {:base_tree => base_tree.reference})
    end

    def create_tree(base_tree_reference, items)
      defs = items.keys.map { |path|
        { path: path, mode: '100644', type: 'blob', sha: items[path] }
      }
      @octokit_client.create_tree(content_repo, defs, {:base_tree => base_tree_reference}).sha
    end

    def create_commit(head_reference, tree_reference, commit_message)
      @octokit_client.create_commit(content_repo, commit_message, tree_reference, head_reference).sha
    end

    def update_head_ref_to(commit_reference)
      @octokit_client.update_ref(content_repo, 'heads/master', commit_reference, false)
    end

    def get_file_content(path)
      @octokit_client.contents(content_repo, path: path, accept: 'application/vnd.github.v3+json')
    end

    def update_content(gitfile, new_content, message)
      @octokit_client.update_contents(content_repo, gitfile.path, message, gitfile.sha, new_content)
    end

    def delete_content(path, sha, message)
      @octokit_client.delete_contents(content_repo, path, message, sha)
    end

    private

    def content_repo
      repo_qualified_name(@settings)
    end

    def authenticated_octokit_client
      if ENV['GITHUB_OAUTH_TOKEN'].nil?
        raise StandardError.new 'Cannot access Github API: GITHUB_OAUTH_TOKEN not set'
      end
      Octokit::Client.new(access_token: ENV['GITHUB_OAUTH_TOKEN'])
    end

  end

end
