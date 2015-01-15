require_relative '../github/github'
require_relative '../utilities/log'
require_relative '../model/content'
require_relative '../exceptions/unprocessable_entity_error'
require_relative '../metadata/metadata'
require_relative '../services/file_path_provider'
require_relative '../metadata/metadata_factory'
require_relative '../web/service_http_response'
require 'json'

module Hacienda

  class CreateContentController

    GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE = 'Content item created'
    GENERIC_METADATA_CREATED_COMMIT_MESSAGE = 'Created metadata file'

    def initialize(github, content_digest)
      @github = github
      @content_digest = content_digest
      @file_path_provider = FilePathProvider.new
      @metadata_factory = MetadataFactory.new
    end

    def create(type, data, locale, author)

      content = Content.from_create(data)

      json_path = @file_path_provider.draft_json_path_for(content.id, type, locale)
      metadata_path = @file_path_provider.metadata_path_for(content.id, type)

      Log.context action: 'creating', id: content.id do

        if @github.content_exists?(metadata_path)
          response = ServiceHttpResponseFactory.conflict_response
        else
          sha_of_referenced_files = content.referenced_files.collect { |item| create_html_file(item, type, locale).sha }
          json_file_sha = create_json_file(content.data, json_path).sha

          create_metadata_file(content, locale, metadata_path, author)

          draft_version = @content_digest.generate_digest(sha_of_referenced_files.unshift(json_file_sha))

          response = ServiceHttpResponseFactory.created_response({
            versions: {
              draft: draft_version,
              public: nil
            }
          }.to_json)

          response.etag = draft_version
          response.location = "#{type}/#{content.id}/#{locale}"
          response.content_type = 'application/json'
        end

        response
      end

    end

    private

    def create_metadata_file(content, locale, path, author)
      metadata = @metadata_factory.create(content.id, locale, DateTime.now, author)
      @github.create_content(path, metadata.to_json, GENERIC_METADATA_CREATED_COMMIT_MESSAGE)
    end

    def create_json_file(data_hash, path)
      @github.create_content(path, data_hash.to_json, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE)
    end

    def create_html_file(item, type, locale)
      file_path = @file_path_provider.draft_path_for(item.file_name, type, locale)
      @github.create_content(file_path, item.value, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE)
    end

  end

end
