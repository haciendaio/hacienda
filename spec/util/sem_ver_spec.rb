require_relative '../spec_helper'
require_relative '../../util/sem_ver'

include SemVer

describe SemVer do

  it 'should leave the major.minor.patch as it is' do
     expect(SemVer::from_raw_git_describe("1.2.7")).to eq "1.2.7"
  end

  it 'should leave the major.minor.patch as it is for multidigits' do
     expect(SemVer::from_raw_git_describe("5.32.17")).to eq "5.32.17"
  end

  it 'should use +build.xx.sha instead of .sha' do
    expect(SemVer::from_raw_git_describe("0.21.7-123-ed56234a")).to eq "0.21.7.ed56234a"
  end

end
