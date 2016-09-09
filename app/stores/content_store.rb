require_relative '../../app/stores/translation_store'
require_relative '../exceptions/file_not_found_error'
require_relative '../../app/model/content_query'
require_relative '../../app/utilities/execution_time_logger'

require 'json'

module Hacienda

  class ContentStore

    include ExecutionTimeLogger

    def initialize(state, query, content_handlers, file_data_store, log, local_git_repo = nil, translation_store = TranslationStore.new(file_data_store, log))
      @state = state
      @query = query
      @content_handlers = content_handlers
      @file_data_store = file_data_store
      @translation_store = translation_store
      @local_git_repo = local_git_repo
      @log = log
    end

    def find_locale_resource(type, id, locale, changes_in_the_past = 0)
      file_path = "#{@state}/#{locale}/#{type}/#{id}.json"
      @local_git_repo.get_version_for_file_at(file_path, changes_in_the_past)
    end

    def find_one(type, id, locale)
      log_execution_time_of('find_one') do
        data = @translation_store.get_translation(@state.to_s, type, id, locale)
        enrich_item(data, ContentQuery.new(@state, locale, type, id))
        data
      end
    end

    def find_all(type, locale)
      log_execution_time_of('find_all') do
        all_content = []

        begin
          all_translations = @translation_store.get_translations_for(@state.to_s, type, locale)
          all_translations.each do |translation|
            enrich_item(translation, ContentQuery.new(@state, locale, type, translation[:id], :collection))
            all_content << translation
          end
        rescue FileNotFoundError
          @log.info("Trying to find all items of type #{type} but did not find any")
        end

        @query.apply(all_content)
      end

    end

    private

    def enrich_item(data, query)
      @content_handlers.each { |handler| handler.process!(data, query) }
    end

  end

end
