require_relative 'support/functional_test_helper'
require_relative 'support/test_content_manager'

require_relative '../../spec/shared/navigation'
require_relative '../shared/metadata_builder'
require_relative '../shared/content_item'

module Hacienda
  module Test

    describe ContentStore do
      include Navigation

      def clear_test_repositories
        FileUtils.rm_rf TEST_REPO
      end

      before :all do
        app.set :content_directory_path, TEST_REPO
      end

      before :each do
        clear_test_repositories
      end

      let(:default_metadata) { MetadataBuilder.new.default.build }

      it 'should return a 404 status code for non-existent content item' do
        status_code = get_draft_translated_response_status_code_for('penguin', 'obviously-non-existent-item', 'en')
        status_code.should eq 404
      end

      describe 'draft content' do

        let (:test_content_manager) { TestContentManager.new(TEST_REPO)}

        let (:nellie) { {id: 'nellie', title: 'Nellie the Elephant'} }
        let (:babar)  { {id: 'babar', title: 'Babar the Elephant'} }
        let (:dumbo)  { {id: 'dumbo', title: 'Dumbo the Elephant'} }

        before :each do
          test_content_manager.add_item('draft', 'en', 'circus', 'nellie', nellie, default_metadata)
          test_content_manager.add_item('draft', 'en', 'circus', 'babar', babar, default_metadata)
          test_content_manager.add_item('draft', 'en', 'circus', 'dumbo', dumbo, default_metadata)
        end

        it 'should return an individual content item' do
          item = get_draft_translated_item_by_id('circus', 'nellie', 'en')
          item[:title].should eq('Nellie the Elephant')
        end

        it 'should return all content items' do
          items = get_draft_items('circus', 'en')

          expect(items).to have(3).items
          items.map { |item| item[:title] }.should match_array(['Babar the Elephant', 'Dumbo the Elephant', 'Nellie the Elephant'])
        end

        describe 'version reporting' do

          it 'should include the version of a new draft item in its locale' do
            a_content_item = ContentItem.new

            item_version = test_content_manager.add_draft_item(a_content_item)

            actual_item_hash = get_item_for_locale(a_content_item, a_content_item.locale)

            expect(actual_item_hash[:versions][:draft]).to eq(item_version)
            expect(actual_item_hash[:versions][:public]).to eq(nil)
          end

          it 'should not add version or status when finding all items (by default), because it takes forever' do
            items = get_draft_items('circus', 'en')

            expect(items).to have(3).items
            items.each { |item| item.keys.should match_array([:id, :title, :translated_locale, :last_modified, :last_modified_by,
                                                              :version, :versions]) }
          end

        end
      end

      describe 'public content' do

        let (:test_content_manager) { TestContentManager.new(TEST_REPO) }

        let (:nellie) { {id: 'nellie', title: 'Nellie the Elephant'} }
        let (:babar)  { {id: 'babar', title: 'Babar the english Elephant'} }
        let (:dumbo)  { {id: 'dumbo', title: 'Dumbo the Elephant'} }

        before :each do
          nellie_metadata = MetadataBuilder.new.with_canonical('es').with_draft_languages('es').with_public_languages('es').build
          babar_metadata = MetadataBuilder.new.with_canonical('de').with_draft_languages('de', 'en').with_public_languages('de', 'en').build
          dumbo_metadata = MetadataBuilder.new.with_canonical('de').with_draft_languages('de', 'cn','pt').with_public_languages('de','pt').build

          test_content_manager.add_item('public', 'es', 'circus', 'nellie', nellie, nellie_metadata)
          test_content_manager.add_item('public', 'en', 'circus', 'babar', babar, babar_metadata)
          test_content_manager.add_item('public', 'pt', 'circus', 'dumbo', dumbo, dumbo_metadata)
        end

        it 'should return an individual content item' do
          item = get_public_translated_item_by_id('circus', 'babar', 'cn')

          expect(item[:title]).to eq('Babar the english Elephant')
        end

        it 'should return all content items' do
          items = get_public_items('circus', 'pt')

          expect(items).to have(3).items
          items.map { |item| item[:title] }.should match_array(['Babar the english Elephant', 'Dumbo the Elephant', 'Nellie the Elephant'])
        end
      end

      describe 'merging referenced content' do
        let (:test_content_manager) { TestContentManager.new(TEST_REPO)}

        it 'should merge the contents of a referenced html file' do
          html_content = '<p>I wanna know.... how you scored that goal.</p>'
          riise = {id: 'riise', title: 'John Arne Riise', five_times_ref: 'riise_body.html'}

          test_content_manager.add_item('draft', 'en', 'lfc', 'riise', riise, default_metadata)
          test_content_manager.add_ref_file('draft', 'en', 'lfc', 'riise_body.html', html_content)

          item = get_draft_translated_item_by_id('lfc', 'riise', 'en')
          expect(item[:five_times_html]).to eq(html_content)
        end
      end

      describe 'localised content' do
        let (:test_content_manager) { TestContentManager.new(TEST_REPO)}

        let(:german_item) { {id: 'penguin', title: 'Pingu der Pinguin'} }
        let(:english_item) { {id: 'penguin', title: 'Pingu the Penguin'} }
        let(:canonical_item) { {id: 'cat', title: 'persian cat', food: 'meat'} }

        let(:metadata_cat) { MetadataBuilder.new.with_id('cat').with_canonical('es').with_draft_languages('es').without_last_modified.build }
        let(:date_for_german_language) { DateTime.new(1995, 4, 4) }

        let(:metadata_with_en_and_de) {
           MetadataBuilder.new
            .with_id('cat')
            .with_canonical('en')
            .with_draft_languages('en','de')
            .with_last_modified(:en, DateTime.new(2014, 7, 7))
            .with_last_modified(:de, date_for_german_language)
            .build
          }

        before :each do
          test_content_manager.add_item('draft', 'en', 'animal', 'penguin', english_item, metadata_with_en_and_de)
          test_content_manager.add_item('draft', 'de', 'animal', 'penguin', german_item, metadata_with_en_and_de)
          test_content_manager.add_item('draft', 'es', 'animal', 'cat', canonical_item, metadata_cat)
        end

        it 'should return the item in the requested language if the requested language exists' do
          item = get_draft_translated_item_by_id('animal', 'penguin', 'de')

          clean_returned_json(item)

          expect(item).to include german_item.merge(translated_locale: 'de').merge(last_modified: date_for_german_language.to_s)
        end

        it 'should return the english item if the requested language does not exists' do
          item = get_draft_translated_item_by_id('animal', 'penguin', 'cn')

          clean_returned_json(item)

          expect(item).to include english_item.merge(translated_locale: 'en').merge(last_modified: '2014-07-07T00:00:00+00:00')
        end

        it 'should return the canonical language if the requested language and english language do not exist' do
          item = get_draft_translated_item_by_id('animal', 'cat', 'cn')

          clean_returned_json(item)

          expect(item).to include canonical_item.merge(translated_locale: 'es').merge(last_modified: '1970-01-01T00:00:00+00:00')
        end

      end

      describe 'all the items translated' do
        let (:test_content_manager) { TestContentManager.new(TEST_REPO)}

        it 'should return translated versions for all the items of a type' do
          cat_item = {id: 'cat', title:'chinese cat', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author'}
          cat_metadata =  MetadataBuilder.new
                            .with_id('cat')
                            .with_canonical('cn')
                            .with_draft_languages('cn')
                            .with_public_languages('cn')
                            .with_last_modified('cn', DateTime.new(2000, 1, 1))
                            .with_last_modified_by('cn', 'author')
                            .build

          dog_item = {id: 'dog', title:'english dog', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author'}
          dog_metadata = MetadataBuilder.new
                            .with_id('dog')
                            .with_canonical('cn')
                            .with_draft_languages('cn', 'en')
                            .with_public_languages('cn')
                            .with_last_modified('en', DateTime.new(2000, 1, 1))
                            .with_last_modified_by('en', 'author')
                            .build

          cow_item = {id: 'cow', title:'german cow', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author' }
          cow_metadata = MetadataBuilder.new
                            .with_id('cow')
                            .with_canonical('cn')
                            .with_draft_languages('cn', 'en', 'de')
                            .with_public_languages('cn')
                            .with_last_modified('de', DateTime.new(2000, 1, 1))
                            .with_last_modified_by('de', 'author')
                            .build

          test_content_manager.add_item('draft', 'cn', 'animal', 'cat', cat_item, cat_metadata)
          test_content_manager.add_item('draft', 'en', 'animal', 'dog', dog_item, dog_metadata)
          cow_version_hash = test_content_manager.add_item('draft', 'de', 'animal', 'cow', cow_item, cow_metadata)

          untranslated_version_hash = {version:nil, versions: { draft:nil, public:nil}}

          items = get_draft_items('animal', 'de')

          expect(items.size).to eq 3
          expect(items).to match_array([
            cat_item.merge(translated_locale: 'cn').merge(untranslated_version_hash),
            dog_item.merge(translated_locale: 'en').merge(untranslated_version_hash),
            cow_item.merge(translated_locale: 'de').merge(version: cow_version_hash, versions: {draft: cow_version_hash, public: nil})
          ])

        end
      end

      describe 'history of items' do
        let (:test_content_manager) { TestContentManager.new(TEST_REPO)}

        it 'should retrieve one version in the past' do
          first_cat_item = {id: 'cat', title:'cat number one', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author'}
          second_cat_item = {id: 'cat', title:'cat number two', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author'}
          third_cat_item = {id: 'cat', title:'cat number three', last_modified: DateTime.new(2000, 1, 1).to_s, last_modified_by: 'author'}
          default_cat_metadata =  MetadataBuilder.new
          .with_id('cat')
          .with_canonical('cn')
          .with_draft_languages('cn')
          .with_public_languages('cn')
          .with_last_modified('cn', DateTime.new(2000, 1, 1))
          .with_last_modified_by('cn', 'author')
          .build

          test_content_manager.add_item('draft', 'cn', 'animal', 'cat', first_cat_item, default_cat_metadata)
          test_content_manager.add_item('draft', 'cn', 'animal', 'cat', second_cat_item, default_cat_metadata)
          test_content_manager.add_item('draft', 'cn', 'animal', 'cat', third_cat_item, default_cat_metadata)

          item = get_draft_item_version('animal', 'cat', 'cn', 1)

          expect(item[:title]).to eq 'cat number two'
        end

      end

      def clean_returned_json(item)
        item.reject! do |key, value|
          key == :status or key == :version
        end
      end
    end
  end
end
