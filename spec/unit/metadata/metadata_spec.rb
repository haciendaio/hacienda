require_relative '../unit_helper'
require_relative '../../shared/metadata_builder'
require_relative '../../../app/metadata/metadata'

module Hacienda
  module Test

    describe Metadata do

      it 'should return false if metadata is empty' do
        metadata = Metadata.new(MetadataBuilder.new.build)
        expect(metadata.has_languages?).to be false
      end

      it 'should return true if metadata is not empty' do
        metadata = Metadata.new(MetadataBuilder.new.with_draft_languages('en').build)
        expect(metadata.has_languages?).to be true
      end

      describe '#any_translation_in?' do
        let(:builder) { MetadataBuilder.new }

        it 'should return true for public if any public languages' do
          published_metadata = builder.with_public_languages('pt').build_object

          expect(published_metadata.any_translation_in?('public')).to eq true
        end

        it 'should return true for draft if any draft languages' do
          drafted_metadata = builder.with_draft_languages('cn').build_object

          expect(drafted_metadata.any_translation_in?('draft')).to eq true
        end

        it 'should return false for public if no public languages' do
          unpublished_metadata = builder.with_no_public_languages.build_object

          expect(unpublished_metadata.any_translation_in?('public')).to eq false
        end

        it 'should return false for draft if no draft languages' do
          unpublished_metadata = builder.with_no_draft_languages.build_object

          expect(unpublished_metadata.any_translation_in?('draft')).to eq false
        end
      end

      describe 'remove metadata for specific locale' do

        it 'should remove a language from draft languages' do
          metadata = Metadata.new(MetadataBuilder.new.with_draft_languages('en', 'es').build)
          metadata.remove_for_locale('en')
          expect(metadata.draft_languages).to eq ['es']
        end

        it 'should remove a language from public languages' do
          metadata = Metadata.new(MetadataBuilder.new.with_public_languages('en', 'es').build)
          metadata.remove_for_locale('en')
          expect(metadata.public_languages).to eq ['es']
        end

        it 'should remove the last modified' do
          metadata = Metadata.new(MetadataBuilder.new.with_last_modified('en', '2000-1-1').build)
          metadata.remove_for_locale('en')
          expect(metadata.last_modified('en')).to eq DateTime.parse('1970-1-1').to_s
        end

        it 'should remove the last modified by' do
          metadata = Metadata.new(MetadataBuilder.new.with_last_modified_by('es', 'Spanish author').with_last_modified_by('en', 'English author').build)
          metadata.remove_for_locale('en')
          expect(metadata.last_modified_by('en')).to eq 'Unknown'
        end

      end

      it 'should add a language to draft languages' do
        metadata = Metadata.new(MetadataBuilder.new.with_draft_languages('en', 'es').build)
        metadata.add_draft_language('cn')

        expect(metadata.draft_languages).to match_array ['en', 'es', 'cn']
      end

      it 'should add a language to public languages' do
        metadata = Metadata.new(MetadataBuilder.new.with_public_languages('en', 'es').build)
        metadata.add_public_language('cn')

        expect(metadata.public_languages).to match_array ['en', 'es', 'cn']
      end

      it 'should return a json representation' do
        metadata = Metadata.new(MetadataBuilder.new
                                .with_id('haha-id')
                                .with_canonical('en')
                                .with_draft_languages('en')
                                .with_public_languages('en', 'pt')
                                .with_last_modified('en', DateTime.new(2014, 1, 2))
                                .with_last_modified_by('en', 'some author')
                                .build)

        metadata_hash = {
            id: 'haha-id',
            canonical_language: 'en',
            available_languages: {
                draft: ['en'],
                public: ['en', 'pt']
            },
            last_modified: {
                en: '2014-01-02T00:00:00+00:00'
            },
            last_modified_by: {
                en: 'some author'
            }
        }

        expect(metadata.to_json).to eq metadata_hash.to_json
      end

      describe 'last_modified' do
        it 'should use the modified datetime if present' do
          metadata = Metadata.new(MetadataBuilder.new.with_last_modified('en', DateTime.new(1984, 1, 1).to_s).build)

          expect(metadata.last_modified('en')).to eq(DateTime.new(1984, 1, 1).to_s)
        end

        it 'should provide default time if missing' do
          metadata = Metadata.new(MetadataBuilder.new.without_last_modified.build)

          expect(metadata.last_modified('en')).to eq(DateTime.new(1970, 1, 1).to_s)
        end

        it '#update_last_modified' do
          metadata = Metadata.new(MetadataBuilder.new.with_last_modified('en', DateTime.new(2014, 1, 1).to_s).build)

          metadata.update_last_modified('en', DateTime.new(2014, 2, 2))

          expect(metadata.last_modified('en')).to eq(DateTime.new(2014, 2, 2).to_s)
        end

        it '#update_last_modified when no last_modified date is set' do
          metadata = Metadata.new(MetadataBuilder.new.without_last_modified.build)

          metadata.update_last_modified('en', DateTime.new(2014, 2, 2))

          expect(metadata.last_modified('en')).to eq(DateTime.new(2014, 2, 2).to_s)
        end

      end

      describe 'get last_modified_by' do
        context 'content has a last modified by for the locale' do
          it 'should return the last modified by' do
            metadata = Metadata.new(MetadataBuilder.new.with_last_modified_by('en', 'author').build)

            expect(metadata.last_modified_by('en')).to eq('author')
          end
        end

        context 'content does not have a last modified by for the requested locale' do
          it 'should return unknown' do
            metadata = Metadata.new(MetadataBuilder.new.with_last_modified_by('en', 'author').build)

            expect(metadata.last_modified_by('es')).to eq('Unknown')
          end
        end

        context 'content does not have any last modified by for any locale' do
          it 'should return unknown' do
            metadata = Metadata.new(MetadataBuilder.new.without_last_modified_by.build)

            expect(metadata.last_modified_by('en')).to eq('Unknown')
          end
        end

      end

      describe 'update last modified by' do
        it '#update_last_modified_by' do
          metadata = Metadata.new(MetadataBuilder.new.with_last_modified_by('en', 'author').build)

          metadata.update_last_modified_by('en', 'new author')
          metadata.update_last_modified_by('es', 'spanish author')

          expect(metadata.last_modified_by('en')).to eq('new author')
          expect(metadata.last_modified_by('es')).to eq('spanish author')
        end

        it '#update_last_modified_by when no last_modified_by is set' do
          metadata = Metadata.new(MetadataBuilder.new.without_last_modified_by.build)

          metadata.update_last_modified_by('en', 'new author')

          expect(metadata.last_modified_by('en')).to eq('new author')
        end
      end

    end
  end
end
