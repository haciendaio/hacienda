require_relative '../unit_helper'
require_relative '../../../app/stores/file_data_store'
require_relative '../../../app/exceptions/file_not_found_error'
require_relative '../../../app/exceptions/bad_file_contents_error'
require_relative '../../../spec/fake_settings'

module Hacienda
  module Test

    describe FileDataStore do
      include FakeSettings

      let(:file_system_wrapper) { double('FileSystemWrapper', find_all_ids: []) }
      let(:raw_content_preparation) { double('RawContentPreparation') }
      let(:log) { double('log', info: nil, debug: nil, error: nil) }

      before :each do
        raw_content_preparation.stub(:process_content!).and_return { |data| data }
      end

      describe '#find_all_ids' do

        let(:items_base_path) { '/base/path' }
        let(:file_data_store) { FileDataStore.new(fake_settings, items_base_path, file_system_wrapper, raw_content_preparation, log) }

        it 'should return all relevant ids' do
          file_system_wrapper.stub(:find_all_ids).with('/base/path', 'draft/en/items').and_return(%w(first second))
          items = file_data_store.find_all_ids 'draft/en/items'
          expect(items).to match_array %w(first second)
        end

      end

      describe '#get_data_for_id' do

        it 'should raise not found error and log when the file cannot be accessed' do
          file_system_wrapper.stub(:read).and_raise(Errno::ENOENT)

          log.should_receive(:error).with("Errors::FileNotFoundError: The file '/some/path/doesnotexists.json' cannot be opened.")

          file_data_store = FileDataStore.new(fake_settings, '/some/path', file_system_wrapper, [], log)
          expect { file_data_store.get_data_for_id('doesnotexists') }.to raise_error(Errors::FileNotFoundError)
        end

        it 'should raise a bad file contents error and log if a file contains invalid JSON data' do
          items_base_path = '/base/path/english/items'

          file_system_wrapper.stub(:read).with("#{items_base_path}/bad.json").and_return('{"this_will_break":"hideously')

          log.should_receive(:error).with("JSON::ParserError: The file '#{items_base_path}/bad.json' contained invalid JSON data.")

          file_data_store = FileDataStore.new(fake_settings, items_base_path, file_system_wrapper, [], log)

          expect { file_data_store.get_data_for_id('bad') }.to raise_error(Errors::BadFileContentsError)
        end

        it 'should process each handler' do
          handlers = [
              double('FirstHandler', :can_handle? => true, :handle! => nil),
              double('SecondHandler', :can_handle? => false, :handle! => nil)
          ]

          file_system_wrapper.stub(:read).and_return({first_field: 'first', second_field: 'second'}.to_json)

          FileDataStore.new(fake_settings, '/some/path', file_system_wrapper, handlers, log).get_data_for_id('items')

          expect(handlers.first).to have_received(:handle!).twice
          expect(handlers.last).to_not have_received(:handle!)
        end

      end

    end
  end
end
