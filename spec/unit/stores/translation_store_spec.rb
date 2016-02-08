require_relative '../unit_helper'
require_relative '../../../app/stores/translation_store'
require_relative '../../shared/metadata_builder'
module Hacienda
  module Test

    describe TranslationStore do

      let(:file_data_store) { double('FileDataStore') }
      let(:metadata_factory) { double('MetadataFactory', from: content_metadata) }
      let(:last_modified) { '2014-01-01T00:00:00+00:00' }
      let(:last_modified_by) { 'Ronaldo Nazario' }
      let(:log) { double('log', error: nil) }
      let(:content_metadata) { Hacienda::Metadata.new(MetadataBuilder.new.with_canonical('cn').
          with_draft_languages('cn').
          with_public_languages('cn', 'en').
          with_last_modified('cn', last_modified).with_last_modified_by('cn', last_modified_by).build) }

      subject { TranslationStore.new(file_data_store, metadata_factory, log) }

      describe 'translation of the content' do

        let(:translated_data) { {type: 'tabby', id: 'miao'} }

        it 'should get the requested language when it exists' do
          file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('cat metadata')
          file_data_store.stub(:get_data_for_id).with('public/cn/animal/cat').and_return(translated_data)

          cat = subject.get_translation('public', 'animal', 'cat', 'cn')

          expect(cat[:translated_locale]).to eq 'cn'
        end

        it 'should get the english when requested language does not exist' do
          file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('metadata hash')
          metadata_factory.stub(:from).with('metadata hash').and_return(content_metadata)
          file_data_store.stub(:get_data_for_id).with('public/en/animal/cat').and_return(translated_data)

          returned_cat = subject.get_translation('public', 'animal', 'cat', 'pt')

          expect(returned_cat[:translated_locale]).to eq 'en'
        end

        it 'should get the canonical language when requested language and english do not exists' do
          file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('metadata hash')
          metadata_factory.stub(:from).with('metadata hash').and_return(content_metadata)
          file_data_store.stub(:get_data_for_id).with('draft/cn/animal/cat').and_return(translated_data)

          returned_cat = subject.get_translation('draft', 'animal', 'cat', 'de')

          expect(returned_cat[:translated_locale]).to eq 'cn'
        end

      end

      describe 'adding metadata' do

        before :each do
          file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('cat metadata hash')
          metadata_factory.stub(:from).with('cat metadata hash').and_return(content_metadata)
          file_data_store.stub(:get_data_for_id).with('draft/cn/animal/cat').and_return({})
        end

        it 'should have the last modified date' do
          returned_cat = subject.get_translation('draft', 'animal', 'cat', 'de')

          expect(returned_cat[:last_modified]).to eq last_modified
        end

        it 'should have the author who last modified the resource' do
          returned_cat = subject.get_translation('draft', 'animal', 'cat', 'de')

          expect(returned_cat[:last_modified_by]).to eq last_modified_by
        end
      end

      describe '#get_translations_for' do

        let(:drafted_in_german_metadata) { MetadataBuilder.new.with_draft_only_locale('de').build_object }
        let(:published_in_german_metadata) { MetadataBuilder.new.with_published_locale('de').build_object }

        it 'should retrieve all content items of type in the specified state and language' do
          file_data_store.stub(:find_all_ids).with('metadata/animal').and_return(['cat', 'bat'])

          file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('cat metahash')
          file_data_store.stub(:get_data_for_id).with('metadata/animal/bat').and_return('bat metahash')

          metadata_factory.stub(:from).with('cat metahash').and_return(drafted_in_german_metadata)
          metadata_factory.stub(:from).with('bat metahash').and_return(published_in_german_metadata)

          file_data_store.stub(:get_data_for_id).with('public/de/animal/bat').and_return({id: 'bat'})

          translations = subject.get_translations_for('public', 'animal', 'de')

          expect(translations.size).to eq 1
          expect(translations.first).to include({id: 'bat'})
        end

        context 'when neither requested locale nor canonical is published' do
          let(:cat_metadata) { MetadataBuilder.new
                                   .with_draft_languages('en', 'cn')
                                   .with_canonical('en')
                                   .with_public_languages('en')
                                   .build_object }
          let(:bat_metadata) { MetadataBuilder.new
                                   .with_draft_languages('en', 'cn')
                                   .with_canonical('en')
                                   .with_public_languages('en')
                                   .build_object }
          let(:dog_metadata) { MetadataBuilder.new
                                   .with_draft_languages('en', 'cn')
                                   .with_canonical('en')
                                   .with_public_languages('cn')
                                   .build_object }

          before {
            file_data_store.stub(:find_all_ids).with('metadata/animal').and_return(['cat', 'bat', 'dog'])

            file_data_store.stub(:get_data_for_id).with('metadata/animal/cat').and_return('cat metahash')
            file_data_store.stub(:get_data_for_id).with('metadata/animal/bat').and_return('bat metahash')
            file_data_store.stub(:get_data_for_id).with('metadata/animal/dog').and_return('dog metahash')

            metadata_factory.stub(:from).with('cat metahash').and_return(cat_metadata)
            metadata_factory.stub(:from).with('bat metahash').and_return(bat_metadata)
            metadata_factory.stub(:from).with('dog metahash').and_return(dog_metadata)

            file_data_store.stub(:get_data_for_id).with('public/en/animal/bat').and_return({id: 'bat'})
            file_data_store.stub(:get_data_for_id).with('public/en/animal/cat').and_return({id: 'cat'})
            file_data_store.stub(:get_data_for_id).with('public/en/animal/dog').and_raise(Errors::FileNotFoundError.new('dog'))
          }

          it 'should only return the available translations' do
            translations = subject.get_translations_for('public', 'animal', 'en')

            expect(translations.size).to eq 2

            expect(translations[0]).to include({id: 'cat'})
            expect(translations[1]).to include({id: 'bat'})
          end

          it 'should log when FileNotFoundError is raised' do
            subject.get_translations_for('public', 'animal', 'en')

            expect(log).to have_received(:error).with(include 'dog')
          end
        end
      end

    end
  end
end