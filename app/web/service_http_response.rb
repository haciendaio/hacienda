module Hacienda
  class ServiceHttpResponseFactory

    def self.not_found_response
      ServiceHttpResponse.new('', 404)
    end

    def self.conflict_response
      ServiceHttpResponse.new('', 409)
    end

    def self.no_content_response
      ServiceHttpResponse.new('', 204)
    end

    def self.created_response(body = '')
      ServiceHttpResponse.new(body, 201)
    end

    def self.ok_response(body = '')
      ServiceHttpResponse.new(body, 200)
    end

  end

  class ServiceHttpResponse

    attr_reader   :body
    attr_accessor :content_type, :etag, :location, :code

    def initialize(body, code)
      @body = body
      @code = code
      @content_type = nil
      @etag = nil
      @location = nil
    end

    def apply_to_sinatra_response(response)
      response.header['Content-Type'] = content_type if content_type
      response.header['ETag'] = etag if etag
      response.header['Location'] = location if location
      response.status = code
    end

  end
end
