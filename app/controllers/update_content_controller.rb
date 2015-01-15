require_relative '../services/file_path_provider'
require_relative '../metadata/metadata_factory'
require_relative '../github/github'
require_relative '../utilities/log'
require_relative '../model/content'
require_relative '../stores/content_store'
require_relative '../web/service_http_response'

require 'json'

module Hacienda
  class UpdateContentController

    GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE = 'Content item modified'
    GENERIC_METADATA_CHANGED_COMMIT_MESSAGE = 'Modified metadata file'

    def initialize(github, content_digest, content_store, log)
      @github = github
      @content_digest = content_digest
      @file_path_provider = FilePathProvider.new
      @metadata_factory = MetadataFactory.new
      @content_store = content_store
      @log = log
    end

    def update(type, id, data, locale, author)
      content = Content.from_update(id, data)
      metadata_path = @file_path_provider.metadata_path_for(content.id, type)

      Log.context action: 'updating content item', type: type, id: content.id do

        if @github.content_exists?(metadata_path)
          response = update_content(author, content, id, locale, metadata_path, type)
        else
          response = ServiceHttpResponseFactory.not_found_response
        end
        response
      end
    end

    private

    def update_content(author, content, id, locale, metadata_path, type)
      updated_draft_version = get_draft_version(content, locale, type)
      update_metadata(locale, metadata_path, author)

      response = ServiceHttpResponseFactory.ok_response({
                                                          versions: {
                                                            draft: updated_draft_version,
                                                            public: get_public_version(id, locale, type)
                                                          }
                                                        }.to_json)

      response.etag = updated_draft_version
      response.content_type = 'application/json'
      response
    end

    def get_public_version(id, locale, type)
      begin
        @content_store.find_one(type, id, locale)[:versions][:public]
      rescue Errors::FileNotFoundError
        @log.info("Trying to get the public version of type #{type} for id #{id} but did not find any")
        nil
      end
    end

    def get_draft_version(content, locale, type)
      sha_of_referenced_files = content.referenced_files.collect { |item| update_html_file(item, type, locale).sha }
      json_file_sha = update_json_file(content, type, locale).sha
      @content_digest.generate_digest(sha_of_referenced_files.unshift(json_file_sha))
    end

    def update_json_file(content, type, locale)
      content_item_path = @file_path_provider.draft_json_path_for(content.id, type, locale)
      @github.create_content(content_item_path, content.data.to_json, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE)
    end

    def update_html_file(item, type, locale)
      html_path = @file_path_provider.draft_path_for(item.file_name, type, locale)
      @github.create_content(html_path, item.value, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE)
    end

    def update_metadata(locale, metadata_path, author)
      metadata = @metadata_factory.from_string(get_metadata(metadata_path))
      metadata.add_draft_language(locale) unless metadata.has_draft_language?(locale)
      metadata.update_last_modified(locale, DateTime.now)
      metadata.update_last_modified_by(locale, author)
      @github.create_content(metadata_path, metadata.to_json, GENERIC_METADATA_CHANGED_COMMIT_MESSAGE)
    end

    def get_metadata(metadata_path)
      @github.get_content(metadata_path).content
    end

  end
end
