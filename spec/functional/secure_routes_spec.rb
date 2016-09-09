require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../shared/metadata_builder'
require_relative '../../spec/shared/navigation'

module Hacienda
  module Test
    describe 'Security around API routes' do
      include Navigation

      before :all do
        app.set :content_directory_path, TEST_REPO
      end

      let(:test_content_manager) { TestContentManager.new(TEST_REPO) }
      let(:default_metadata) { MetadataBuilder.new.default.build }

      context 'access without authentication information' do
        let(:missing_auth_info) { nil }

        it 'rejects update access' do
          response = update_item('paper', { id: 'some-item' }, 'en', missing_auth_info)
          expect(response.status).to eq 401
        end

        it 'rejects create access' do
          response = create_item('paper', { id: 'some-item' }, 'en', missing_auth_info)
          expect(response.status).to eq 401
        end
      end

      context 'access with incorrect authentication information' do
        let(:wrong_auth_info) {
          {
              secret: 'WRONG SECRET',
              nonce: 'WRONG',
              client_id: 'WRONG',
              timestamp: 'WRONG'
          }
        }
        it 'rejects update access' do
          response = update_item('paper', { id: 'some-item' }, 'en', wrong_auth_info)
          expect(response.status).to eq 401
        end
      end


    end
  end
end
