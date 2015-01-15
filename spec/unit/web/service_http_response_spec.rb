require_relative '../unit_helper'
require_relative '../../../app/web/service_http_response'

module Hacienda
  module Test
    describe ServiceHttpResponse do

      it 'apply to the sinatra response' do
        service_http_response = ServiceHttpResponse.new('response body', 200)
        service_http_response.content_type = 'application/json'
        service_http_response.etag = 'some-version'
        service_http_response.location = 'some/path'

        headers = {}
        sinatra_response = double('Sinatra::Response', 'header' => headers, 'status=' => nil )
        service_http_response.apply_to_sinatra_response(sinatra_response)

        expect(headers).to include('Content-Type' => 'application/json', 'ETag' => 'some-version', 'Location' => 'some/path')
        expect(sinatra_response).to have_received(:'status=').with(200)
      end

      it 'should not set content-type, location or etag when they are not set' do
        service_http_response = ServiceHttpResponse.new('response body', 200)

        headers = {}
        sinatra_response = double('Sinatra::Response', 'header' => headers, 'status=' => nil )
        service_http_response.apply_to_sinatra_response(sinatra_response)

        expect(headers.keys).not_to include('Content-Type', 'ETag', 'Location')
      end

      it 'should contain the body of the response' do
        body = 'some response body'

        service_http_response = ServiceHttpResponse.new(body, 200)

        expect(service_http_response.body).to eq 'some response body'
      end
    end
  end
end
