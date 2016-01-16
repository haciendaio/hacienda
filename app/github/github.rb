require 'octokit'
require 'base64'
require 'ostruct'

require_relative '../exceptions/not_found_exception'
require_relative '../exceptions/unauthorized_exception'
require_relative '../exceptions/git_hub_exception'

require_relative '../utilities/execution_time_logger'
require_relative '../utilities/retry'
require_relative '../utilities/log'

require_relative 'github_client'
require_relative 'git_file'

module Hacienda

  class Github

    include ExecutionTimeLogger
    include Retry

    def initialize(settings, github_client = GithubClient.new(settings), log = Log.new(settings))
      @settings = settings
      @log = log
      @github_client = github_client
    end

    def create_content(commit_message, items = {})
      content, path = path_and_content(items)

      content_reference = @github_client.create_blob(content)

      log_execution_time_of('Changing remote content') do
        retry_for_a_number_of_attempts(3, Octokit::UnprocessableEntity) do

          commit_reference = create_commit_reference(commit_message, content_reference, path)

          @github_client.update_head_ref_to(commit_reference)

          { path => GitFile.new(content, path, content_reference) }
        end
      end
    end

    def delete_content(path, commit_message = '', options={})
      retry_timeout_s = options[:retry_timeout_s] || 3
      should_retry = true
      begin
        @log.info("Deleting: #{path}")
        github_response = @github_client.get_file_content(path)

        head_reference = @github_client.get_head_reference
        @log.info("head/master ref before deletion is:#{head_reference}")

        commit_reference = @github_client.delete_content(path, github_response.sha, commit_message)

        head_reference = @github_client.get_head_reference
        @log.info("head/master ref after deletion is:#{head_reference}")

        @log.info("sha we want to make head/ref is:#{commit_reference.commit.sha}")

      rescue Octokit::Conflict => e
        if should_retry
          @log.info("got conflict: #{e} - retrying...")
          should_retry = false
          sleep retry_timeout_s
          retry
        end
        @log.info('retried out, raising...')
        raise
      rescue Octokit::NotFound => e
        raise Errors::NotFoundException, e.message
      end
    end

    def get_content(path)
      begin
        log_execution_time_of('Retrieving remote content') do
          github_response = @github_client.get_file_content(path)
          GitFile.new(Base64.decode64(github_response.content), github_response.path, github_response.sha)
        end
      rescue Octokit::NotFound => e
        raise Errors::NotFoundException, e.message
      end
    end

    def content_exists?(path)
      begin
        !!get_content(path)
      rescue Errors::NotFoundException
        return false
      end
    end


    def remove_path_from_tree(tree, path)
      tree.reject do |file_metadata|
        file_metadata[:path] == path
      end
    end

    private

    def create_commit_reference(commit_message, content_reference, path)
      head_reference = @github_client.get_head_reference

      base_tree_reference = @github_client.get_tree(head_reference)
      tree_reference = @github_client.create_tree(base_tree_reference, content_reference, path)
      @github_client.create_commit(head_reference, tree_reference, commit_message)
    end

    def path_and_content(items)
      raise "Cannot create content items, since can only cope with 1 item at moment: #{items}" unless items.keys.size == 1

      path = items.keys.first
      content = items[path]
      return content, path
    end
  end
end