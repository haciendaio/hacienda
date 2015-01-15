require_relative '../../unit_helper'
require_relative '../../../../app/stores/file_handlers/referenced_file_handler'

module Hacienda
  module Test

    describe ReferencedFileHandler do

      let(:file_system_wrapper) {double('FileSystemWrapper', :strip_path_and_extension => 'stripped!')}

      it 'should handle any referenced key' do
        handler = ReferencedFileHandler.new(file_system_wrapper)
        expect(handler.can_handle?('xxx_ref')).to be_true
        expect(handler.can_handle?('xxx_other')).to be_false
      end

      it 'should load referenced files' do
        raw_data = { some_field_ref: 'first/second/another_file.html' }

        file_system_wrapper.stub(:full_path_of_referenced_file).and_return('/rootdir/subdir1/subdir2/another_file.html')
        file_system_wrapper.stub(:extname).with('/rootdir/subdir1/subdir2/another_file.html').and_return('.html')
        file_system_wrapper.stub(:exists?).with('/rootdir/subdir1/subdir2/another_file.html').and_return(true)
        file_system_wrapper.stub(:read).and_return('<h1>Some HTML stuff</h1>')

        handler = ReferencedFileHandler.new(file_system_wrapper)
        handler.handle!(raw_data, :some_field_ref, 'first/second/another_file.json')

        raw_data[:some_field_html].should eq('<h1>Some HTML stuff</h1>')
      end

    end
  end
end
