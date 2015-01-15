require_relative '../utilities/log'
require_relative '../exceptions/file_not_found_error'
require_relative '../exceptions/bad_file_contents_error'
require_relative '../utilities/execution_time_logger'

require 'pathname'
require 'json'

module Hacienda

  include ExecutionTimeLogger

  class FileDataStore

    def initialize(settings, data_dir, file_system_wrapper, handlers, log = Log.new(settings))
      @data_dir = data_dir
      @log = log
      @file_system_wrapper = file_system_wrapper
      @handlers = handlers
    end

    def get_data_for_id(id)
      filename = "#{@data_dir}/#{id}.json"

      begin
        build_file_data(filename)
      rescue Errno::ENOENT
        @log.error "Errors::FileNotFoundError: The file '#{filename}' cannot be opened."
        raise Errors::FileNotFoundError.new(filename)
      rescue JSON::ParserError
        @log.error "JSON::ParserError: The file '#{filename}' contained invalid JSON data."
        raise Errors::BadFileContentsError
      end

    end

    def find_all_ids(path)
      @file_system_wrapper.find_all_ids(@data_dir, path)
    end

    private

    def build_file_data(filename)
      data = load_json(filename)
      apply_handlers(data, filename)
      data
    end

    def apply_handlers(data, filename)
      data.keys.each do |key|
        @handlers.each { |handler| handler.handle!(data, key, filename) if handler.can_handle?(key) }
      end
    end

    def load_json(filename)
      JSON.parse(@file_system_wrapper.read(filename), symbolize_names: true)
    end

  end
end