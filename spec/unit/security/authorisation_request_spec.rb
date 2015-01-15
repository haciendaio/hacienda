require_relative '../unit_helper'
require_relative '../../../app/security/authorisation_request'

module Hacienda
  module Security
    module Test

      describe 'AuthorisationRequest' do

        let(:body) { double('body', read: 'THE_BODY', rewind: nil) }

        it 'should report missing headers if a header is missing' do
          auth_request = AuthorisationRequest.new(body, {'HTTP_NONCE' => '', 'HTTP_TIMESTAMP' => '', 'HTTP_AUTHORIZATION' => '', 'rack.request.form_vars' => ''})

          auth_request.has_missing_headers?.should be_true
        end

        it 'should report false if all headers are present' do
          auth_request = AuthorisationRequest.new(body, {'HTTP_CLIENTID' => '', 'HTTP_NONCE' => '', 'HTTP_TIMESTAMP' => '', 'HTTP_AUTHORIZATION' => '', 'rack.request.form_vars' => ''})
          auth_request.has_missing_headers?.should be_false
        end

        it 'should split out authorisation cryptographic hash from authorisation header' do
          auth_request = AuthorisationRequest.new(body, {'HTTP_AUTHORIZATION' => 'HMAC ahash'})
          auth_request.authorization_hash.should == 'ahash'
        end

        it 'should read the body form the body stream' do
          auth_request = AuthorisationRequest.new(body, {'HTTP_AUTHORIZATION' => 'HMAC ahash'})
          expect(auth_request.body).to eq('THE_BODY')
        end

        it 'should reset the body stream ready for the next use' do
          AuthorisationRequest.new(body, {'HTTP_AUTHORIZATION' => 'HMAC ahash'})
          expect(body).to have_received(:rewind)
        end

      end
    end
  end
end
