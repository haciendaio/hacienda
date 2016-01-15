require_relative '../integration_helper'
require_relative '../../spec/fake_settings'
require_relative '../../app/github/github'
require_relative '../utilities/fake_config_loader'

module Hacienda
  module Test
    describe Github do

      include FakeSettings

      let(:settings) {  FakeConfigLoader.new.load_config 'test' }

      it 'should delete stuff' do
        github = Github.new(settings)

        github.create_content('Committed...', 'black/white/cat.txt' => 'Postman Pat')
        github.delete_content('black/white/cat.txt', 'Deleted')

      end

      context 'incomplete environment' do

        it 'should fail nicely if required environment not set' do

          begin
            initial_oauth_token = ENV['GITHUB_OAUTH_TOKEN']
            ENV.delete 'GITHUB_OAUTH_TOKEN'

            expect {
              Github.new(settings).create_content('...', 'whatever' => 'something')
            }.to raise_error { |error|
              expect(error.message).to include 'GITHUB_OAUTH_TOKEN'
            }

          ensure
            ENV['GITHUB_OAUTH_TOKEN'] = initial_oauth_token
          end

        end

      end

    end
  end
end
