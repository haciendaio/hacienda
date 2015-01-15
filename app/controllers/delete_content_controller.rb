require_relative '../utilities/log'
require_relative '../metadata/metadata'
require_relative '../metadata/metadata_factory'
require_relative '../services/file_path_provider'
require_relative '../web/service_http_response'

module Hacienda
  class DeleteContentController

    GENERIC_CONTENT_DELETE_COMMIT_MESSAGE = 'Content item deleted'
    GENERIC_METADATA_DELETE_COMMIT_MESSAGE = 'Deleted metadata file'
    GENERIC_METADATA_UPDATE_COMMIT_MESSAGE = 'Updated metadata file'

    def initialize(github, log, file_path_provider = FilePathProvider.new, metadata_factory = MetadataFactory.new)
      @github = github
      @file_path_provider = file_path_provider
      @log = log
      @metadata_factory = metadata_factory
    end

    def delete(id, type, locale = 'en')
      Log.context action: 'deleting', id: id do
        begin
          delete_public(id, locale, type)
          delete_draft(id, locale, type)
          update_metadata(id, locale, type)

          ServiceHttpResponseFactory.no_content_response
        rescue Errors::NotFoundException
          @log.info("Trying to delete an intem of type #{type} with id #{id} but did not find any")
          ServiceHttpResponseFactory.not_found_response
        end
      end
    end

    def delete_all(type, id)
      Log.context action: 'deleting all', id: id do
        begin
          metadata_path = @file_path_provider.metadata_path_for(id, type)

          metadata = @metadata_factory.from_string(@github.get_content(metadata_path).content)

          @github.delete_content(metadata_path)

          metadata.draft_languages.each do |language|
            @github.delete_content(@file_path_provider.draft_json_path_for(id, type, language))
          end

          metadata.public_languages.each do |language|
            @github.delete_content(@file_path_provider.public_json_path_for(id, type, language))
          end

          ServiceHttpResponseFactory.no_content_response
        rescue Errors::NotFoundException
          @log.info("Trying to delete all items of type #{type} and id #{id} but did not find any")
          ServiceHttpResponseFactory.not_found_response
        end
      end
    end

    private

    def update_metadata(id, locale, type)
      begin
        metadata_path = @file_path_provider.metadata_path_for(id, type)
        metadata = @metadata_factory.from(get_metadata(metadata_path))

        metadata.remove_for_locale(locale)

        if metadata.has_languages?
          @github.create_content(metadata_path, metadata.to_json, GENERIC_METADATA_UPDATE_COMMIT_MESSAGE)
        else
          @github.delete_content(metadata_path, GENERIC_METADATA_DELETE_COMMIT_MESSAGE)
        end
      rescue Errors::NotFoundException
        @log.info("Trying to delete or retrieve metadata but the metadata file does not exist for the item: #{id}")
      end
    end

    def get_metadata(metadata_path)
      JSON.parse(@github.get_content(metadata_path).content, symbolize_names: true)
    end

    def delete_public(id, locale, type)
      begin
        @github.delete_content(@file_path_provider.public_json_path_for(id, type, locale), GENERIC_CONTENT_DELETE_COMMIT_MESSAGE)
      rescue Errors::NotFoundException
        @log.info("Trying to delete public version but it does not exist for the item: #{id} - locale:#{locale}")
      end
    end

    def delete_draft(id, locale, type)
      @github.delete_content(@file_path_provider.draft_json_path_for(id, type, locale), GENERIC_CONTENT_DELETE_COMMIT_MESSAGE)
    end

  end
end