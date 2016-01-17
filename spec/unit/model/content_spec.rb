require_relative '../unit_helper'
require_relative '../../../app/model/content'
require_relative '../../../app/exceptions/unprocessable_entity_error'

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

          it 'should remove the translated_locale field' do
            content = Content.new('bob', { :translated_locale => 'cn'}, type: 'cat', locale: 'en', referenced_files: [])
            expect(content.data).to be_empty
          end

        end

      end
    end
  end
end
