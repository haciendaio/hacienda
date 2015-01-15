require_relative '../integration_helper'
require_relative '../../app/stores/file_data_store'
require_relative '../../app/utilities/file_system_wrapper'
require_relative '../../app/stores/file_handlers/referenced_file_handler'
require_relative '../../spec/fake_settings'

module Hacienda
  module Test

    describe FileDataStore do
      include FakeSettings

      let(:file_system_wrapper) { FileSystemWrapper.new }
      let(:handlers) { [ ReferencedFileHandler.new(file_system_wrapper) ] }
      let(:files_root) { 'build/data/file_data_store_spec/repo' }

      it 'should load some content' do
        pretty_colours = %w(green red blue)

        create_json_files(pretty_colours, root: files_root, in: 'en/postie')

        store = FileDataStore.new(fake_settings, files_root, file_system_wrapper, handlers)
        all = store.find_all_ids('en/postie')

        expect(all).to match_array pretty_colours
      end

      it 'should load content from referenced file' do
        create_file('reffing.json', {'football_ref' => 'football.html'}.to_json, root: files_root, in: 'en/misc')
        create_file('football.html', '<p>ja, football ist schlimm</p>', root: files_root, in: 'en/misc')

        store = FileDataStore.new(fake_settings, files_root, file_system_wrapper, handlers)
        data = store.get_data_for_id('en/misc/reffing')

        expect(data[:football_html]).to eq '<p>ja, football ist schlimm</p>'
      end

      it 'should not fall over if value is a boolean' do
        create_file('programming.json', {'is_ruby_ace' => true}.to_json, root: files_root, in: 'en/misc')

        store = FileDataStore.new(fake_settings, files_root, file_system_wrapper, handlers)

        data = store.get_data_for_id('en/misc/programming')

        expect(data[:is_ruby_ace]).to eq true
      end

      it 'should not fall over if referenced file doesnt exist' do
        create_file('invalid-reffing.json', {'invalid_ref' => 'doesnt_exist.slim'}.to_json, root: files_root, in: 'en/misc')

        store = FileDataStore.new(fake_settings, files_root, file_system_wrapper, handlers)
        data = store.get_data_for_id('en/misc/invalid-reffing')

        expect(data[:invalid_ref]).to eq 'doesnt_exist.slim'
        expect(data.has_key?(:invalid)).to be_false
      end

      def create_file(name, content, options)
        create_single_file(content, name, options)
      end

      def create_json_files(names, options)
        names.each do |name|
          content = "{\"name\": \"#{name}\"}"
          create_single_file(content, "#{name}.json", options)
        end
      end

      def target_dir(options)
        "#{options[:root]}/#{options[:in]}"
      end

      def create_single_file(content, name, options)
        dir = target_dir(options)
        FileUtils.mkpath dir unless File.directory?(dir)
        File.open(File.join(dir, name), 'w') do |f|
          f.write(content)
        end
      end

    end

  end
end
