require_relative '../../../app/utilities/rugged_wrapper'

module Hacienda
  module Test
    describe RuggedWrapper do

      describe 'retrieving versions in the past' do

        before :each do
          @file_path = 'file/path'
          
          @walker = MockRuggedWalker.new([make_commit_with_oid('a commit'), make_commit_with_oid('another commit'), make_commit_with_oid('yet another commit')])
          @repo = double('Rugged::Repository', last_commit: make_commit_with_oid('last commit'), close: nil)
          @repo.stub(:blob_at).with('last commit', @file_path).and_return(make_blob_with_oid('last commit content'))
          @repo.stub(:blob_at).with('second to last commit', @file_path).and_return(make_blob_with_oid('last commit content'))
          @repo.stub(:blob_at).with('another commit', @file_path).and_return(make_blob_with_oid('another commit content'))
          @repo.stub(:blob_at).with('yet another commit', @file_path).and_return(make_blob_with_oid('yet another commit content'))
          @rugged_wrapper = RuggedWrapper.new(repo: @repo, walker: @walker)
        end

        it 'should return the last commit when looking for 0 versions in the past' do
          expect(@rugged_wrapper.get_version_in_past(@file_path, 0).oid).to eq 'last commit content'
        end

        it 'should return the second to last commit when looking for 1 version in the past' do
          expect(@rugged_wrapper.get_version_in_past(@file_path, 1).oid).to eq 'another commit content'
        end

        it 'should return the nil when looking for a lot of versions in the past' do
          expect(@rugged_wrapper.get_version_in_past(@file_path, 10)).to be_nil
        end

        it 'should throw invalid argument when the version is a negative number' do
          expect { @rugged_wrapper.get_version_in_past(@file_path, -10) }.to raise_error
        end
        
        it('should close the repository after completion') do
          @rugged_wrapper.get_version_in_past(@file_path, 0)
          expect(@repo).to have_received(:close)
        end

        def make_blob_with_oid oid
          double('blob', oid: oid)
        end

        def make_commit_with_oid oid
          double('commit', oid: oid)
        end

        class MockRuggedWalker
          def initialize commits
            @commits = commits
          end

          def push commit
            @commits[0] = commit
          end

          def each &block
            @commits.each &block
          end
        end

      end

    end
  end
end
