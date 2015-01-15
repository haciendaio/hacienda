require_relative '../integration_helper'

require_relative '../../app/web/wiring'
require_relative '../../app/stores/content_store'

require_relative '../../spec/fake_settings'
require 'pathname'


module Hacienda
  module Test
    describe ContentStore do

      describe 'loading referenced content file' do

        include Wiring
        include FakeSettings

        let(:settings) { fake_settings_with(:content_directory_path, "#{Pathname.new(__FILE__).dirname}/content_store_spec_content") }
        let(:request) { double('Request', env: {'rack.request.query_hash' => {}}) }
        let(:public_content_id) { 'continuous-delivery-key-to-innovation' }

        it 'should load file referenced from json relative to json path' do
          content = public_content_store.find_one(:news, 'continuous-delivery-key-to-innovation', 'en')
          expect(content[:content_body_html]).to start_with 'referenced content body'
        end

        it 'should provide only public items for published items' do
          public_news = public_content_store.find_all(:news, 'en')

          expect(public_news.size).to eq 1
          expect(public_news.first[:id]).to eq public_content_id
        end
      end
    end

  end
end
