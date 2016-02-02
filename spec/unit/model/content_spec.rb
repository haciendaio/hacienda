require_relative '../unit_helper'
require_relative '../../../app/model/content'
require_relative '../../../app/exceptions/unprocessable_entity_error'
require_relative '../github/in_memory_file_system'
require_relative '../../../app/metadata/metadata_factory'

module Hacienda
  module Test
    describe Content do
      describe '#build' do
        let(:type_args) { {type: 'cat', locale: 'en'} }
        it 'should raise error on empty id' do
          expect {
            Content.build('', {}, type_args)
          }.to raise_error Errors::UnprocessableEntityError, 'An ID must be specified.'
        end

        it 'should raise error on nil id' do
          expect {
            Content.build(nil, {}, type_args)
          }.to raise_error Errors::UnprocessableEntityError, 'An ID must be specified.'
        end

        it 'should raise an argument error when the title is over 150 chars' do
          id_with_151_chars = 'really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-r'

          expect {
            Content.build(id_with_151_chars, {}, type_args)
          }.to raise_error Errors::UnprocessableEntityError, 'The ID must not exceed 150 characters in length.'
        end
      end

      describe '#new' do
        context 'removing unneeded fields' do
          it 'removes remove the translated_locale field' do
            content = Content.new('bob', { :translated_locale => 'cn'}, type: 'cat', locale: 'en', referenced_files: [])
            expect(content.data).to be_empty
          end
        end
      end

      describe '#write_to' do
        let(:file_system) { InMemoryFileSystem.new }
        let(:files) { file_system.test_api }
        let(:metadata_factory) { MetadataFactory.new }
        let(:datetime) { DateTime.new(2014, 1, 1)}
        let(:content_digest) { double('content_digest', generate_digest: 'DIGEST') }

        context 'creating new content item' do
          let(:author) { 'some author' }
          let(:new_content_data) {{
              'id' => 'reindeer',
              'type' => 'mammal',
              'field' => 'value'
          }}

          let(:new_content) { Content.build('reindeer', new_content_data, type: 'mammal', locale: 'pt', datetime: datetime) }

          it 'creates a metadata file' do
            expected_metadata = MetadataFactory.new.create('reindeer', 'pt', datetime, author)

            new_content.write_to(file_system, author, 'create new content', content_digest)

            expect(files.content_of 'metadata/mammal/reindeer.json').to eq expected_metadata.to_json
          end

          it 'creates the draft json file' do
            new_content.write_to(file_system, author, 'create new content', content_digest)

            expect(files.exists? 'draft/pt/mammal/reindeer.json').to be_true
          end
        end

        context 'content exists in one locale' do
          let(:existing_locale) { 'es' }
          let(:existing_metadata) { metadata_factory.create('reindeer', existing_locale, datetime.to_s, 'old author')}
          let(:metadata_path) {'metadata/mammal/reindeer.json'}

          before {
            files.setup metadata_path => existing_metadata.to_json
          }

          context 'updating content' do
            context 'updating content item in existing locale' do

              let(:new_content_data) {{
                  'id' => 'reindeer',
                  'type' => 'mammal',
                  'prancer_html' => 'antler'
              }}
              let(:new_content) { Content.build('reindeer', new_content_data, type: 'mammal', locale: existing_locale) }

              before {
                new_content.write_to(file_system, 'new author', 'new description', content_digest)
              }

              describe 'content files handling' do
                it 'updates content files' do
                  expect(files.content_of 'draft/es/mammal/reindeer.json').to eq({
                                                                                     'id' => 'reindeer',
                                                                                     'type' => 'mammal',
                                                                                     'prancer_ref' => 'reindeer-prancer.html'
                                                                                 }.to_json)
                  expect(files.content_of 'draft/es/mammal/reindeer-prancer.html').to eq 'antler'
                end
              end

              describe 'metadata handling' do
                let(:updated_metadata) { metadata_factory.from_string(files.content_of metadata_path) }

                it 'does not update metadata languages' do
                  expect(updated_metadata.canonical_language).to eq existing_metadata.canonical_language
                  expect(updated_metadata.draft_languages).to eq existing_metadata.draft_languages
                  expect(updated_metadata.public_languages).to eq existing_metadata.public_languages
                end

                it 'updates metadata modified datetime' do
                  expect(updated_metadata.last_modified(existing_locale)).to be > existing_metadata.last_modified(existing_locale)
                end
              end

              describe 'versioning' do
                before {
                  content_digest.stub(:generate_digest).with([
                     files.sha_of('draft/es/mammal/reindeer.json'),
                     files.sha_of('draft/es/mammal/reindeer-prancer.html')
                  ]).and_return('updated-version')

                }

                it 'returns updated content version based on written files shas' do
                  updated_version = new_content.write_to(file_system, 'new author', 'new description', content_digest)

                  expect(updated_version).to eq 'updated-version'
                end

              end
            end

            context 'updating content item in new locale' do

              let(:new_locale) { 'fr' }
              let(:new_content_data) {{
                  'id' => 'reindeer',
                  'type' => 'mammal',
                  'prancer_html' => 'le antler'
              }}
              let(:new_content) { Content.build('reindeer', new_content_data, type: 'mammal', locale: new_locale) }

              before {
                new_content.write_to(file_system, 'new author', 'new description', content_digest)
              }

              describe 'new locale content files handling' do
                it 'updates content files' do
                  expect(files.content_of "draft/#{new_locale}/mammal/reindeer.json").to eq({
                                                                                     'id' => 'reindeer',
                                                                                     'type' => 'mammal',
                                                                                     'prancer_ref' => 'reindeer-prancer.html'
                                                                                 }.to_json)
                  expect(files.content_of "draft/#{new_locale}/mammal/reindeer-prancer.html").to eq 'le antler'
                end
              end

              describe 'metadata handling' do
                let(:updated_metadata) { metadata_factory.from_string(files.content_of metadata_path) }

                it 'does not change canonical language' do
                  expect(updated_metadata.canonical_language).to eq existing_metadata.canonical_language
                end

                it 'adds new language to draft languages' do
                  expect(updated_metadata.draft_languages).to eq existing_metadata.draft_languages + [ new_locale ]
                  expect(updated_metadata.public_languages).to eq existing_metadata.public_languages
                end

                it 'does not change modified datetime for existing locale' do
                  expect(updated_metadata.last_modified(existing_locale)).to eq existing_metadata.last_modified(existing_locale)
                end

                it 'updates modified datetime for new locale' do
                  expect(updated_metadata.last_modified(new_locale)).to be > existing_metadata.last_modified(existing_locale)
                end
              end
            end
          end
        end
      end

    end
  end
end
