require_relative 'service_http_response'
require_relative '../services/file_path_provider'
require_relative '../utilities/log'
require_relative '../utilities/file_system_wrapper'
require_relative '../utilities/shell_executor'
require_relative '../github/logging_github_client'
require_relative '../github/github_client'
require_relative '../github/github_file_system'
require_relative '../lib/content_digest'
require_relative '../controllers/create_content_controller'
require_relative '../controllers/delete_content_controller'
require_relative '../controllers/publish_content_controller'
require_relative '../controllers/update_content_controller'
require_relative '../stores/file_data_store'
require_relative '../stores/file_handlers/referenced_file_handler'
require_relative '../stores/content_handlers/ensure_id_handler'
require_relative '../stores/content_handlers/version_content_handler'
require_relative '../stores/local_git_repo'
require_relative '../stores/content_store'
require_relative '../query/query_runner'

module Hacienda
  module Wiring

    def content_digest
      ContentDigest.new(settings.content_directory_path, ShellExecutor.new, file_system_wrapper)
    end

    def file_path_provider
      FilePathProvider.new
    end

    def query(query_hash)
      QueryRunner.new(query_hash)
    end

    def draft_content_store
      ContentStore.new(:draft, query(request.env['rack.request.query_hash']), content_handlers, content_file_store, log, local_content_repo)
    end

    def public_content_store
      ContentStore.new(:public, query(request.env['rack.request.query_hash']), content_handlers, content_file_store, log, local_content_repo)
    end

    def github_file_system
      GithubFileSystem.new(settings, logging_github_client)
    end

    def logging_github_client
      LoggingGithubClient.new github_client, log
    end

    def github_client
      GithubClient.new settings
    end

    def publish_content_controller
      PublishContentController.new(github_file_system, content_digest, log)
    end

    def create_content_controller
      CreateContentController.new(github_file_system, content_digest)
    end

    def delete_content_controller
      DeleteContentController.new(github_file_system, log)
    end

    def update_content_controller
      UpdateContentController.new(github_file_system, content_digest, draft_content_store, log)
    end

    def file_system_wrapper
      FileSystemWrapper.new
    end

    def content_file_store
      FileDataStore.new(settings, settings.content_directory_path, file_system_wrapper, file_handlers)
    end

    def file_handlers
      [
          ReferencedFileHandler.new(file_system_wrapper)
      ]
    end

    def content_handlers
      [
          VersionContentHandler.new(content_digest, file_path_provider),
          EnsureIdHandler.new
      ]
    end

    def local_content_repo
      LocalGitRepo.new(settings.content_directory_path, settings)
    end

    def halt_if
      Halt.new(self)
    end

    def error_handler
      Errors::RequestErrorHandler.new(settings, self)
    end

    def log
      Log.new settings
    end

  end

end
