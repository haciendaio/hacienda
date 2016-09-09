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

  class GithubFileSystem

    include ExecutionTimeLogger
    include Retry

    def initialize(settings, github_client = GithubClient.new(settings), log = Log.new(settings))
      @settings = settings
      @log = log
      @github_client = github_client
    end

    def write_files(description, items = {})
      raise "Need some content items to create" if items.empty?

      log_execution_time_of('Changing remote content') do
        retry_for_a_number_of_attempts(3, Octokit::UnprocessableEntity) do

          head_reference = @github_client.get_head_reference
          base_tree_reference = @github_client.get_tree(head_reference)

          paths_to_refs = {}
          items.each_pair do |path, content|
            paths_to_refs[path] = @github_client.create_blob(content)
          end

          tree_reference = @github_client.create_tree(base_tree_reference, paths_to_refs)
          create_commit_reference_value = @github_client.create_commit(head_reference, tree_reference, description)
          commit_reference = create_commit_reference_value

          @github_client.update_head_ref_to(commit_reference)

          paths_to_refs.map {|path, content_reference|
            [path, GitFile.new(items[path], path, content_reference)]
          }.to_h
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


  end
end