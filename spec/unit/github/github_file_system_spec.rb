require_relative '../unit_helper'
require_relative '../../../app/github/github_file_system'
require 'ostruct'

module Hacienda
  module Test
    describe GithubFileSystem do

      let(:github) { GithubFileSystem.new(settings, github_client, log) }

      let(:description) { 'some commit message' }
      let(:settings) { double('Settings', content_repo: 'repo') }
      let(:log) { double('Logger', info: nil, warn: nil) }
      let(:github_client) { double('GithubClient',
                                   get_head_reference: 'head_reference',
                                   create_blob: 'content_reference',
                                   create_tree: 'tree_reference',
                                   create_commit: 'commit_reference',
                                   get_tree: 'old_tree_reference',
                                   delete_content: nil,
                                   get_file_content: nil,
                                   update_head_ref_to: nil)
      }

      context '#write_files' do

        it 'should create content blob' do
          github.write_files(description, 'path' => 'content')
          expect(github_client).to have_received(:create_blob).with('content')
        end

        it 'should create new tree based on the tree of the head commit' do
          github_client.stub(:get_tree).with('head_reference').and_return('base_tree_reference')

          github.write_files(description, 'path' => 'content')
          expect(github_client).to have_received(:create_tree).with('base_tree_reference', {'path' => 'content_reference'})
        end

        it 'should create new commit' do
          github.write_files(description, 'path' => 'content')
          expect(github_client).to have_received(:create_commit).with('head_reference', 'tree_reference', description)
        end

        it 'should update the reference' do
          github.write_files(description, 'path' => 'content')
          expect(github_client).to have_received(:update_head_ref_to).with('commit_reference')
        end

        it 'should return a new git file' do
          github_client.stub(:create_blob).and_return('sha1')
          files = github.write_files(description, 'path' => 'content')

          file = files['path']

          expect(files.keys.size).to eq 1
          expect(file.path).to eq('path')
          expect(file.content).to eq('content')
          expect(file.sha).to eq 'sha1'
        end

        describe 'multiple content item handling' do

          it 'should not allow creating no content items' do
            expect {
              github.write_files description, {}
            }.to raise_error
          end

          it 'should not allow call without items' do
            expect {
              github.write_files description
            }.to raise_error
          end

          it 'should allow creating more than one content items' do
            github.write_files(description, 'bob.txt' => 'hi',
                                                    'foo/bar/red.txt' => 'blue')
            expect(github_client).to have_received(:create_blob).twice
          end
        end

      end

      context 'Reading Content' do

        let(:content) { 'content' }
        let(:response_sha) { 'response_sha' }
        let(:github_client) { double('GithubClient', get_file_content: OpenStruct.new(sha: response_sha, path: nil, content: Base64.strict_encode64(content))) }
        let(:github) { GithubFileSystem.new(settings, github_client, log) }

        before :each do
          @file = github.get_content('/en/cats.txt')
        end

        it 'should read a content item' do
          expect(github_client).to have_received(:get_file_content).with('/en/cats.txt')
        end

        it 'should be a GitFile' do
          expect(@file).to be_a GitFile
          expect(@file.content).to eq content
        end

        it 'should raise a not found exception if the item does not exist' do
          github_client.stub(:get_file_content).and_raise(Octokit::NotFound)
          expect { github.get_content('test/does-not-exists') }.to raise_error(Errors::NotFoundException)
        end

      end

      context 'Content exists?' do

        let(:github_client) { double('GithubClient', get_file_content: nil) }

        it 'should return false if the content does not exists' do
          github_client.stub(:get_file_content).and_raise(Octokit::NotFound)
          expect(github.content_exists?('/en/cats.txt')).to be_false
          end

        it 'should return true if the content does exists' do
          github_client.stub(:get_file_content).and_return(OpenStruct.new(sha: nil, path: nil, content: ''))
          expect(github.content_exists?('/en/cats.txt')).to be_true
        end

      end

      context 'Delete content' do
        let(:description) { 'deletion commit message' }

        it 'should raise NotFound exception when not find the content to delete' do
          github_client.stub(:get_file_content).and_raise(Octokit::NotFound)
          expect { github.delete_content('some/path', description)}.to raise_error(Errors::NotFoundException)
        end

        it 'should delegate to github client for delete' do
          github_client.stub(:get_file_content).and_return(OpenStruct.new(sha: 'some sha', path: nil, content: ''))
          github_client.stub(:delete_content).and_return(OpenStruct.new(commit: OpenStruct.new(sha: 'commit sha')))
          github.delete_content('some/path', description)

          expect(github_client).to have_received(:get_file_content).with('some/path')
          expect(github_client).to have_received(:delete_content).with('some/path', 'some sha', description)
          #TODO:  Removing update of the head/ref as it seems to be updated by the delete content api call
          # expect(github_client).to have_received(:update_head_ref_to).with('commit sha')
        end

        it 'should retry if delete fails with 409 error' do
          github_client.stub(:get_file_content).and_return(OpenStruct.new(sha: 'some sha', path: nil, content: ''))

          first_call = true
          github_client.stub(:delete_content) {
            if first_call
              first_call = false
              raise Octokit::Conflict
            end
            OpenStruct.new(commit: OpenStruct.new(sha: 'commit sha'))
          }

          github.delete_content('some/path', description, retry_timeout_s: 0.001)

          expect(github_client).to have_received(:delete_content).twice
        end

        it 'should only retry once even if client always failing' do
          github_client.stub(:get_file_content).and_return(OpenStruct.new(sha: 'some sha', path: nil, content: ''))

          github_client.stub(:delete_content).and_raise Octokit::Conflict.new

          expect {
            github.delete_content('some/path', description, retry_timeout_s: 0.001)
          }.to raise_error

          expect(github_client).to have_received(:delete_content).twice
        end
      end
    end
  end
end