require_relative '../unit_helper'
require_relative '../../../app/model/content'
require_relative '../../../app/exceptions/unprocessable_entity_error'

module Hacienda
  module Test
    describe Content do
      describe '#new' do

        it 'should raise error on empty id' do
          expect {
            Content.new('', {}, [])
          }.to raise_error Errors::UnprocessableEntityError, 'An ID must be specified.'
        end

        it 'should raise error on nil id' do
          expect {
            Content.new(nil, {}, [])
          }.to raise_error Errors::UnprocessableEntityError, 'An ID must be specified.'
        end

        it 'should raise an argument error when the title is over 150 chars' do
          id_with_151_chars = 'really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-really-long-id-r'

          expect {
            Content.new(id_with_151_chars, {}, [])
          }.to raise_error Errors::UnprocessableEntityError, 'The ID must not exceed 150 characters in length.'
        end

        context 'removing unneeded fields' do

          it 'should remove the translated_locale field' do
            content = Content.new('bob', { :translated_locale => 'cn' }, [])
            expect(content.data).to be_empty
          end

        end

      end
    end
  end
end
