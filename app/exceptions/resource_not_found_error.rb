require_relative 'raised_exception'

module Hacienda
  module Errors
    class ResourceNotFoundError < RaisedException

      def initialize(path)
        super(404, "No resource at #{path}", false)
      end

    end
  end
end