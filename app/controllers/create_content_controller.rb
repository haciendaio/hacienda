require_relative '../github/github'
require_relative '../utilities/log'
require_relative '../model/content'
require_relative '../exceptions/unprocessable_entity_error'
require_relative '../metadata/metadata'
require_relative '../metadata/metadata_factory'
require_relative '../web/service_http_response'
require 'json'

module Hacienda

  class CreateContentController

    GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE = 'Content item created'

    def initialize(github, content_digest)
      @github = github
      @content_digest = content_digest
      @metadata_factory = MetadataFactory.new
    end

    def create(type, content_json, locale, author)

      content_data = JSON.parse(content_json)
      content = Content.build(content_data['id'], content_data, type: type, locale: locale)

      json_path = content.json_file_path
      metadata_path = content.metadata_file_path

      Log.context action: 'creating', id: content.id do

        if @github.content_exists?(metadata_path)
          response = ServiceHttpResponseFactory.conflict_response
        else
          sha_of_referenced_files = content.referenced_files.collect { |file|
            create_html_file(content, file).sha
          }

          metadata = @metadata_factory.create(content.id, locale, DateTime.now, author)

          created = @github.write_files(GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE,
                                                     json_path => content.data.to_json,
                                                     metadata_path => metadata.to_json)
          json_file_sha = created[json_path].sha

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

    def create_html_file(content, file)
      @github.write_files(GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE, content.referenced_file_path(file) => file.value).values.first
    end

  end

end
