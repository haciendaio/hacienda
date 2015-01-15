require_relative '../unit_helper'
require_relative '../../../app/lib/content_digest'
require_relative '../../../app/services/file_path_provider'

module Hacienda
  module Test
    describe ContentDigest do

      let(:repo_path) {'../bottle'}
      let(:executor) {double('executor', run: nil)}
      let(:file_system_wrapper) {double('FileSystemWrapper', exists?: nil)}
      let(:git_wrapper_factory) { double('RuggedWrapperFactory', get_repo: git_wrapper) }
      let(:git_wrapper) { double('RuggedWrapper', sha_for: nil) }

      let(:content_digest) {ContentDigest.new(repo_path, executor, file_system_wrapper, git_wrapper_factory)}

      it 'should return item version as nil for non-existent content' do
        file_system_wrapper.stub(:exists?).and_return(false)

        version = content_digest.item_version('whatever-path', 'some-other-path')

        expect(version).to be_nil
      end

      describe '#item_version' do
        it 'should calculate item_version base on two file paths' do
          file_system_wrapper.stub(:exists?).and_return(true)
          git_wrapper.stub(:sha_for).and_return("FIRSTSHA", "SECONDSHA")

          version = Digest::SHA2.new.update('FIRSTSHA'+'SECONDSHA').to_s

          expect(content_digest.item_version('path1', 'path2')).to eq version
        end

        it 'should calculate item_version base on one file path' do
          file_system_wrapper.stub(:exists?).with("#{repo_path}/path1").and_return(true)
          file_system_wrapper.stub(:exists?).with("#{repo_path}/path2").and_return(false)

          git_wrapper.stub(:sha_for).and_return("FIRSTSHA")
          version = Digest::SHA2.new.update('FIRSTSHA').to_s
          expect(content_digest.item_version('path1', 'path2')).to eq version
        end

        it 'should return nil for item_version when neither version exist' do
          file_system_wrapper.stub(:exists?).and_return(false)

          expect(content_digest.item_version('path1', 'path2')).to eq nil
        end
      end

      it 'should generate a digest based on an array of shas' do
        version = Digest::SHA2.new.update('FIRSTSHA'+'SECONDSHA').to_s
        expect(content_digest.generate_digest(['FIRSTSHA', 'SECONDSHA'])).to eq version
      end

      describe 'getting sha using git wrapper' do

        it 'should return the sha of a file' do
          file_system_wrapper.stub(:exists?).and_return(true)
          git_wrapper.stub(:sha_for).with('/some/file/path').and_return('some-sha')

          expect(content_digest.get_sha_for('/some/file/path')).to eq 'some-sha'
        end

        it 'should return an empty string when the file does not exist' do
          file_system_wrapper.stub(:exists?).and_return(false)

          expect(content_digest.get_sha_for('/some/file/path')).to eq ''
        end

      end

    end

  end
end
