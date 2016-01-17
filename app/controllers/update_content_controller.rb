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
      sha_of_referenced_files = shas(content, locale, type)
      metadata = compose_metadata(author, locale, metadata_path)

      content_item_path = @file_path_provider.draft_json_path_for(content.id, type, locale)

      updated_files = @github.write_files(GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE,
                                             content_item_path => content.data.to_json, metadata_path => metadata.to_json)
      updated_json_file = updated_files[content_item_path]

      json_file_sha = updated_json_file.sha
      updated_draft_version = @content_digest.generate_digest(sha_of_referenced_files.unshift(json_file_sha))

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

    def shas(content, locale, type)
      content.referenced_files.collect { |item| update_html_file(item, type, locale).sha }
    end

    def update_html_file(item, type, locale)
      html_path = @file_path_provider.draft_path_for(item.file_name, type, locale)
      @github.write_files(GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE, html_path => item.value).values.first
    end

    def compose_metadata(author, locale, metadata_path)
      metadata = @metadata_factory.from_string(get_metadata(metadata_path))
      metadata.add_draft_language(locale) unless metadata.has_draft_language?(locale)
      metadata.update_last_modified(locale, DateTime.now)
      metadata.update_last_modified_by(locale, author)
      metadata
    end

    def get_metadata(metadata_path)
      @github.get_content(metadata_path).content
    end

  end
end
