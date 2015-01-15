require 'fileutils'
require_relative '../../app/metadata/metadata_factory'

def environments_to_verify
  override = ENV['DATA_INTEGRITY_SPEC_ENVIRONMENTS']
  if override
    return override.split(',')
  end
  %w(test)
end

def repos_base_dir
  Pathname.new(__dir__).join '../../build/integrity_spec/repos/'
end

module Hacienda
  module Test

    describe 'consistent repository' do

      shared_examples :consistency do

        before(:each) {
          ensure_repo_exists
          ensure_repo_pulled
        }

        it 'should have a metadata file for each draft content data item' do
          data_item_identities = identities_in('draft/*/*/*.json')
          metadata_identities = identities_in('metadata/*/*.json')

          check_all(data_item_identities) do |data_identity|
            expect(metadata_identities).to include data_identity
          end
        end

        it 'should have a metadata file for each public content data item' do
          data_item_identities = identities_in('public/*/*/*.json')
          metadata_identities = identities_in('metadata/*/*.json')

          check_all(data_item_identities) do |data_identity|
            expect(metadata_identities).to include data_identity
          end
        end

        it 'should have a metadata file entry for each draft content data item' do
          data_item_translations = translation_identities_in('draft/*/*/*.json')
          metadata_translations = draft_metadata_translation_identities_in('metadata/*/*.json')

          check_all(data_item_translations) do |data_translation|
            expect(metadata_translations).to include data_translation
          end
        end

        it 'should have a metadata file entry for each public content data item' do
          data_item_translations = translation_identities_in('public/*/*/*.json')
          metadata_translations = public_metadata_translation_identities_in('metadata/*/*.json')

          check_all(data_item_translations) do |data_translation|
            expect(metadata_translations).to include data_translation
          end
        end

        it 'should have a data file for each draft metadata translation identity' do
          metadata_translations = draft_metadata_translation_identities_in('metadata/*/*.json')
          data_item_translations = translation_identities_in('draft/*/*/*.json')

          check_all(metadata_translations) do |metadata_translation|
            expect(data_item_translations).to include metadata_translation
          end
        end

        it 'should have a data file for each public metadata translation identity' do
          metadata_translations = public_metadata_translation_identities_in('metadata/*/*.json')
          data_item_translations = translation_identities_in('public/*/*/*.json')

          check_all(metadata_translations) do |metadata_translation|
            expect(data_item_translations).to include metadata_translation
          end
        end

        it 'should check for orphaned metadata files with empty values for both draft and public'

      end

      environments_to_verify.each do |env|
        context env do
          let(:repo_name) { "tw.#{env}.content" }
          let(:exclusions) {
            # are you kidding me?
            []
          }
          include_examples :consistency
        end
      end

      def draft_metadata_translation_identities_in(in_repo_spec)
        metadata_translation_identities(in_repo_spec, 'draft')
      end

      def public_metadata_translation_identities_in(in_repo_spec)
        metadata_translation_identities(in_repo_spec, 'public')
      end

      def translation_identities_in(in_repo_spec)
        files_in(in_repo_spec).map do |pathname|
          {
              locale: pathname.parent.parent.basename.to_s,
              type: pathname.parent.basename.to_s,
              id: pathname.basename.to_s
          }
        end
      end

      def identities_in(in_repo_spec)
        files_in(in_repo_spec).map do |pathname|
          {
              type: pathname.parent.basename.to_s,
              id: pathname.basename.to_s
          }
        end
      end

      def files_in(in_repo_spec)
        repo_dir = local_repo_dir
        files_spec = repo_dir.to_s + '/' + in_repo_spec
        Dir.glob(files_spec).reject {|f|
          exclusions.any? {|exclusion|
            f.include? exclusion
          }
        }.map {|f|
          Pathname.new(f)
        }
      end

      def check_all(items)
        raise 'There were no items to check, which sounds bad :(' if items.empty?
        failures = []
        items.each {|item|
          begin
            yield item
          rescue Exception => failure
            failures << failure
          end
        }
        unless failures.empty?
          raise failures.first if failures.size == 1
          messages = failure_message(failures)
          raise StandardError.new("#{failures.size} failures, details:\n#{messages}")
        end
      end

      def metadata_translation_identities(in_repo_spec, state)
        errors = []
        identities = files_in(in_repo_spec).map do |pathname|
          begin
            json = File.read pathname.to_s
            metadata = Hacienda::MetadataFactory.new.from_string(json)
            metadata.send("#{state}_languages".to_sym).map do |language|
              {
                  locale: language,
                  type: pathname.parent.basename.to_s,
                  id: pathname.basename.to_s
              }
            end
          rescue => e
            errors << "Metadata parsing failed for path: #{pathname}, error: #{e}, file data:\n#{json}"
          end
        end.flatten
        unless errors.empty?
          message = failure_message(errors)
          raise StandardError.new(message)
        end
        identities
      end

      def failure_message(errors)
        messages = errors.map {|e|
          without_diff = e.to_s.split('Diff:').first
          without_diff.partition('to include').join "\n"
        }.join "\n"
        "Got #{errors.size} errors:\n#{messages}"
      end

      def local_repo_dir
        repos_base_dir.join repo_name
      end

      def ensure_repos_dir_exists
        FileUtils.mkpath(repos_base_dir.to_s) unless Dir.exist?(repos_base_dir.to_s)
      end

      def ensure_repo_exists
        ensure_repos_dir_exists
        unless Dir.exist?(local_repo_dir)
          github_oauth_token = ENV['GITHUB_OAUTH_TOKEN']
          Dir.chdir(repos_base_dir) do
            system "git clone https://#{github_oauth_token}@github.com/www-thoughtworks-com/#{repo_name}.git"
          end
        end
      end

      def ensure_repo_pulled
        if Dir.exist?(local_repo_dir)
          Dir.chdir(local_repo_dir) do
            system 'git pull'
          end
        end
      end
    end
  end
end
