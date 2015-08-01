require_relative '../unit_helper'
require 'json'
require_relative '../../../app/stores/content_store'
require_relative '../../../app/exceptions/file_not_found_error'
require_relative '../../../app/services/file_path_provider'

module Hacienda
  module Test

    describe ContentStore do

      let(:log) { double('log', info: nil) }
      let(:handlers) { [double('FirstHandler', process!: nil), double('SecondHandler', process!: nil)] }
      let(:file_data_store) { double('FileDataStore', find_all_ids: [], get_data_for_id: nil) }
      let(:translation_store) { double('TranslationStore', get_translation_for: '') }
      let(:git_local_store) { double('LocalGitStore') }
      let(:query) { double('QueryRunner', apply: 'filtered content') }

      subject { ContentStore.new(:draft, query, handlers, file_data_store, log, git_local_store, translation_store) }

      context 'Finding specific item' do

        let(:nelly) { {id: 'Nelly', title: 'Elephant'} }

        before :each do
          translation_store.stub(:get_translation).with('draft', 'animals', 'elephant', 'en').and_return(nelly)
        end

        it 'should return the translated resource as json' do
          expect(subject.find_one('animals', 'elephant', 'en')).to include nelly
        end

        it 'should call each of the handlers' do
          subject.find_one('animals', 'elephant', 'en')
          expect(handlers.first).to have_received(:process!).with(nelly, anything)
          expect(handlers.last).to have_received(:process!).with(nelly, anything)
        end

        it 'should log the execution time' do
          subject.find_one('animals', 'elephant', 'en')

          expect(log).to have_received(:info).with(start_with('Logging Execution Time'))
        end

      end

      context 'Finding all' do

        let(:log) { double('log', info: nil) }
        let(:cat) { {id: 'cat'} }
        let(:rabbit) { {id: 'rabbit'} }
        let(:draft_data) do
          {
            'cat' => cat,
            'rabbit' => rabbit
          }
        end

        before :each do
          translation_store.stub(:get_translations_for).with('draft', 'animals', 'en').and_return(draft_data.values)
        end

        it 'should include all items returned by metadata' do
          subject.find_all('animals', 'en')
          expect(query).to have_received(:apply).with([cat, rabbit])
        end

        it 'should query the content items' do
          response = subject.find_all('animals', 'en')

          expect(query).to have_received(:apply)
          expect(response).to include 'filtered content'
        end

        it 'should call each of the handlers' do
          subject.find_all('animals', 'en')
          expect(handlers.first).to have_received(:process!).with(cat, anything)
          expect(handlers.first).to have_received(:process!).with(rabbit, anything)
          expect(handlers.last).to have_received(:process!).with(cat, anything)
          expect(handlers.last).to have_received(:process!).with(rabbit, anything)
        end

        it 'should log the execution time' do
          subject.find_all('animals', 'en')

          expect(log).to have_received(:info).with(start_with('Logging Execution Time'))
        end

      end

    end

  end
end