require_relative '../unit_helper'
require_relative '../../../app/security/hmac_authorisation'
require_relative '../../../spec/fake_settings'

include Hacienda::Test::FakeSettings

module Hacienda
  module Security
    module Test

      describe HMACAuthorisation do

        ONE_MINUTE_IN_SECONDS = 60

        let (:time) { double('Time', now: DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS) }
        let (:key_repository) { double('KeyRepository', {:key_for => 'client_id'}) }
        let (:cryptography) { double('Cryptography', {:generate_authorisation_data => {
                                                       hash: '3B10E9E7B7376F694458344C43FA52BAB04561B28400F0C6D67F56297CAF9F4FEE6B8666E70F89F6B3D5CDDEFCCB66DB78A9E8ED331D4219AE21066FD19B18B2'}
                                                   }) }

        subject { HMACAuthorisation.new(fake_settings, time, key_repository, cryptography) }

        it 'should fail authorisation if the client_id header is missing' do
          request = RequestDoubleBuilder.new.with_client_id(nil).build
          subject.authorised?(request).should be_false
        end

        it 'should fail authorisation if the authorisation header is missing' do
          request = RequestDoubleBuilder.new.with_authorization(nil).build
          subject.authorised?(request).should be_false
        end

        it 'should fail authorisation if the nonce header is missing' do
          request = RequestDoubleBuilder.new.with_nonce(nil).build
          subject.authorised?(request).should be_false
        end

        it 'should fail authorisation if the timestamp header is missing' do
          request = RequestDoubleBuilder.new.with_timestamp(nil).build
          subject.authorised?(request).should be_false
        end

        it 'should authorise when request has correct headers' do
          request = RequestDoubleBuilder.new.build
          subject.authorised?(request).should be_true
        end

        it 'should use a dash in the client ID because Nginx rejects headers with underscore by default' do
          request = RequestDoubleBuilder.new.build
          subject.authorised?(request).should be_true
        end

        it 'should fail authorisation if the client does not exist' do
          request = RequestDoubleBuilder.new.with_client_id('NON_EXISTENT_CLIENT').build

          key_repository.stub(:key_for).with('NON_EXISTENT_CLIENT').and_return(nil)

          subject.authorised?(request).should be_false
        end

        it 'should fail authorisation if the timestamp is further than 1 min in time' do
          request_timestamp = 123456700000
          current_timestamp = request_timestamp + ONE_MINUTE_IN_SECONDS + 100

          time.stub(:now).and_return(current_timestamp.to_s)

          request = RequestDoubleBuilder.new.with_timestamp(request_timestamp.to_s).build

          expect(subject.authorised?(request)).to be_false, 'Request was authorized when it should not have'
        end

        it 'should fail authorisation when hashes do not match' do
          body_stream = double('body_stream', read: 'REQUEST_BODY', rewind: nil)

          request = RequestDoubleBuilder.new
                        .with_client_id('client_id')
                        .with_authorization('HMAC 3B10E9E7B7376F694458344C43FA52BAB04561B28400F0C6D67F56297CAF9F4FEE6B8666E70F89F6B3D5CDDEFCCB66DB78A9E8ED331D4219AE21066FD19B18B2')
                        .with_nonce('84024B89D')
                        .with_body(body_stream)
                        .with_timestamp(DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS)
                        .build


          key_repository.stub(:key_for).with('client_id').and_return('SECRET_KEY')

          cryptography.stub(:generate_authorisation_data).with('REQUEST_BODY', 'SECRET_KEY', '84024B89D', DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS).and_return({hash: 'NON_MATCHING_HASH'})

          subject.authorised?(request).should be_false
        end

        it 'should authorise successfully when hashes match' do
          hash = '3B10E9E7B7376F694458344C43FA52BAB04561B28400F0C6D67F56297CAF9F4FEE6B8666E70F89F6B3D5CDDEFCCB66DB78A9E8ED331D4219AE21066FD19B18B2'
          body_stream = double('body_stream', read: 'REQUEST_BODY', rewind: nil)
          request = RequestDoubleBuilder.new
                        .with_client_id('client_id')
                        .with_authorization("HMAC #{hash}")
                        .with_nonce('84024B89D')
                        .with_body(body_stream)
                        .with_timestamp(DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS)
                        .build

          key_repository.stub(:key_for).with('client_id').and_return('SECRET_KEY')

          cryptography.stub(:generate_authorisation_data).with('REQUEST_BODY', 'SECRET_KEY', '84024B89D', '1234567890').and_return({hash: hash})

          subject.authorised?(request).should be_true
        end

      end

      DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS = 100000

      class RequestDoubleBuilder

        def initialize
          @timestamp = DEFAULT_REQUEST_TIMESTAMP_IN_SECONDS
          @authorization = 'HMAC 3B10E9E7B7376F694458344C43FA52BAB04561B28400F0C6D67F56297CAF9F4FEE6B8666E70F89F6B3D5CDDEFCCB66DB78A9E8ED331D4219AE21066FD19B18B2'
          @nonce = '84024B89D'
          @client_id = 'client_id'
          @body = OpenStruct.new(read: 'a body')
        end

        %w{timestamp authorization nonce body client_id}.each do |field|
          define_method("with_#{field}") do |value|
            instance_variable_set("@#{field}", value)
            self
          end
        end

        def build
          RSpec::Mocks::Mock.new({
                                     env: {
                                         'HTTP_CLIENTID' => @client_id,
                                         'HTTP_AUTHORIZATION' => @authorization,
                                         'HTTP_TIMESTAMP' => @timestamp,
                                         'HTTP_NONCE' => @nonce
                                     },
                                     body: @body
                                 })
        end

      end
    end
  end
end
