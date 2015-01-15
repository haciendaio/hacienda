require_relative '../unit_helper'
require_relative '../../../app/metadata/metadata'
require_relative '../../../app/metadata/metadata_factory'
require 'rspec'

module Hacienda
  module Test

    describe MetadataFactory do

      let(:metadata_hash) { {:id => 'from-hash',
                             :canonical_language => 'pt',
                             :available_languages => {
                                 :draft => ['en', 'pt'],
                                 :public => ['pt']
                             }
      } }
      let(:datetime)  { double('DateTime') }

      it 'should create metadata from hash' do
        metadata = MetadataFactory.new.from(metadata_hash)

        expect(metadata).to be_a Metadata
      end

      it 'should create metadata with the values from the hash' do
        metadata = MetadataFactory.new.from(metadata_hash)

        expect(metadata.id).to eq 'from-hash'
        expect(metadata.canonical_language).to eq 'pt'
        expect(metadata.draft_languages).to eq ['en', 'pt']
        expect(metadata.public_languages).to eq ['pt']
      end

      it 'should create a new metadata from a locale' do
        metadata = MetadataFactory.new.create('some-id', 'ro', datetime, 'some author')

        expect(metadata.id).to eq 'some-id'
        expect(metadata.canonical_language).to eq 'ro'
        expect(metadata.draft_languages).to eq ['ro']
        expect(metadata.public_languages).to eq []
      end

      it 'should create a new metadata with last modified data' do
        metadata = MetadataFactory.new.create('some-id', 'ro', DateTime.new(2014, 1, 1).to_s, 'some author')

        expect(metadata.last_modified('ro')).to eq DateTime.new(2014, 1, 1).to_s
      end

      it 'should create a new metadata with last modified by' do
        metadata = MetadataFactory.new.create('some-id', 'ro', DateTime.new(2014, 1, 1).to_s, 'some author')

        expect(metadata.last_modified_by('ro')).to eq 'some author'
      end

    end
  end
end
