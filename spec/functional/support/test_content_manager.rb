require_relative '../../shared/metadata_builder'
require_relative '../../utilities/test_rugged_wrapper'

module Hacienda
  module Test
    class TestContentManager

      def initialize(repository)
        @repository = repository
        FileUtils.rm_rf repository
        FileUtils.mkdir_p repository
        TestRuggedWrapper.init_git_repo(repository)
      end

      def add_draft_item(item, metadata = MetadataBuilder.new.default.build )
        add_item('draft', item.locale, item.type, item.id, item, metadata)
      end

      def add_public_item(item, metadata = MetadataBuilder.new.default.build )
        add_item('public', item.locale, item.type, item.id, item, metadata)
      end

      def add_item(state, locale, type, id, item_content, metadata_content)
        ensure_directory("#{state}/#{locale}/#{type}")
        ensure_directory("metadata/#{type}")

        item_path = "#{state}/#{locale}/#{type}/#{id}.json"
        metadata_path = "metadata/#{type}/#{id}.json"

        full_item_path = write_file(item_path, item_content.to_json)
        write_file(metadata_path, metadata_content.to_json)
        version_hash(full_item_path)
      end

      def add_ref_file(state, locale, type, filename, item_content)
        item_path = "#{state}/#{locale}/#{type}/#{filename}"

        write_file(item_path, item_content)
      end

      private

      def ensure_directory(directory)
        FileUtils.mkdir_p "#{@repository}/#{directory}"
      end

      def write_file(item_path, file_content)
        path = "#{@repository}/#{item_path}"
        File.open(path, 'w') do |file|
          file.write(file_content)
        end

        git_wrapper = TestRuggedWrapper.new(@repository)
        git_wrapper.commit(file_content, item_path)
        path
      end

      def version_hash(full_item_path)
        Digest::SHA2.new.update(`git hash-object #{full_item_path}`.chomp).to_s # magic!
      end
    end
  end
end

