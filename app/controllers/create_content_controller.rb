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

    def initialize(file_system, content_digest)
      @file_system = file_system
      @content_digest = content_digest
    end

    def create(type, content_json, locale, author)

      content_data = JSON.parse(content_json)
      content = Content.build(content_data['id'], content_data, type: type, locale: locale)

      Log.context action: 'creating', id: content.id do

        if content.exists_in?(@file_system)
          response = ServiceHttpResponseFactory.conflict_response
        else
          draft_version = content.write_to(@file_system, author, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE, @content_digest)

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

  end

end
