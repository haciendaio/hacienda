require_relative '../unit_helper'
require_relative '../../../app/services/file_path_provider'

module Hacienda
  module Test

    describe 'FilePathProvider' do

      let(:file_path_provider) { FilePathProvider.new }

      it 'should provide path for draft assets' do
        file_path_provider.draft_json_path_for('crisps', 'food').should eq 'draft/en/food/crisps.json'
        file_path_provider.draft_html_path_for('crisps', 'food').should eq 'draft/en/food/crisps-content-body.html'
      end

      it 'should provide path for draft assets with specific locale' do
        file_path_provider.draft_json_path_for('crisps', 'food', 'es').should eq 'draft/es/food/crisps.json'
        file_path_provider.draft_html_path_for('crisps', 'food', 'es').should eq 'draft/es/food/crisps-content-body.html'
      end

      it 'should provide path for public assets' do
        file_path_provider.public_json_path_for('crisps', 'food').should eq 'public/en/food/crisps.json'
        file_path_provider.public_html_path_for('crisps', 'food').should eq 'public/en/food/crisps-content-body.html'

        file_path_provider.public_json_path_for('crisps', 'food', 'de').should eq 'public/de/food/crisps.json'
        file_path_provider.public_html_path_for('crisps', 'food', 'pt').should eq 'public/pt/food/crisps-content-body.html'
      end

      it 'should provide resource path for public' do
        file_path_provider.public_path_for('crisps', 'food').should eq 'public/en/food/crisps'
        file_path_provider.public_path_for('crisps', 'food', 'es').should eq 'public/es/food/crisps'
      end

      it 'should provide resource path for draft' do
        file_path_provider.draft_path_for('crisps', 'food').should eq 'draft/en/food/crisps'
        file_path_provider.draft_path_for('crisps', 'food', 'es').should eq 'draft/es/food/crisps'
      end

      it 'should provide path for metadata' do
        file_path_provider.metadata_path_for('crisps', 'food').should eq 'metadata/food/crisps.json'
      end

    end
  end
end