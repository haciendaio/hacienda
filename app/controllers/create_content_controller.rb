require_relative '../github/github_file_system'
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
      id = content_data['id']

      content = Content.build(id, content_data, type: type, locale: locale)

      Log.context action: 'creating', id: content.id do
        if content.exists_in?(@file_system)
          ServiceHttpResponseFactory.conflict_response
        else
          draft_version = content.write_to(@file_system, author, GENERIC_CONTENT_CHANGED_COMMIT_MESSAGE, @content_digest)
          create_response(content, draft_version)
        end
      end

    end

    def create_response(content, draft_version)
      response_data = {
          versions: {
              draft: draft_version,
              public: nil
          }
      }
      update_headers(ServiceHttpResponseFactory.created_response(response_data.to_json), content, draft_version)
    end

    def update_headers(response, content, draft_version)
      response.etag = draft_version
      response.location = "#{content.type}/#{content.id}/#{content.locale}"
      response.content_type = 'application/json'
      response
    end


  end

end
