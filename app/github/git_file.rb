require 'base64'
module Hacienda

  class GitFile
    attr_reader :content, :path, :sha

    def initialize(content, path, sha)
      @path = path
      @content = content
      @sha = sha
    end

  end
end
