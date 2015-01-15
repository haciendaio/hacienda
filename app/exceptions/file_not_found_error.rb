require_relative 'resource_not_found_error'

module Hacienda
  module Errors
    class FileNotFoundError < ResourceNotFoundError
    end
  end
end