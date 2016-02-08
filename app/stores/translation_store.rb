require_relative '../metadata/metadata_factory'
require_relative '../exceptions/file_not_found_error'

module Hacienda
  class TranslationStore

    DEFAULT_LOCALE = 'en'

    def initialize(file_data_store, metadata_factory = MetadataFactory.new, log)
      @file_data_store = file_data_store
      @metadata_factory = metadata_factory
      @log = log
    end

    def get_translations_for(state, type, locale)
      @file_data_store.find_all_ids("metadata/#{type}").collect do |id|
        content_metadata = metadata_for(type, id)

        if content_metadata.any_translation_in?(state)
          begin
            get_translation(state.to_s, type, id, locale)
          rescue Errors::FileNotFoundError => e
            @log.error(e.message)
            nil
          end
        end
      end.reject &:nil?
    end

    def get_translation(state, type, id, locale)
      content_metadata = metadata_for(type, id)
      translated_locale = translated_locale(state, locale, content_metadata)

      translated_content_with_metadata(state, type, id, translated_locale, content_metadata)
    end

    private

    def metadata_for(type, id)
      @metadata_factory.from(@file_data_store.get_data_for_id("metadata/#{type}/#{id}"))
    end

    def translated_locale(state, locale, metadata)
      available_languages = state == 'draft' ? metadata.draft_languages : metadata.public_languages

      if available_languages.include?(locale)
        locale
      elsif available_languages.include?(DEFAULT_LOCALE)
        DEFAULT_LOCALE
      else
        metadata.canonical_language
      end
    end

    def translated_content_with_metadata(state, type, id, translated_locale, metadata)
      translated_data = @file_data_store.get_data_for_id("#{state}/#{translated_locale}/#{type}/#{id}")

      translated_data.merge(:translated_locale => translated_locale)
        .merge(:last_modified => metadata.last_modified(translated_locale).to_s)
        .merge(:last_modified_by => metadata.last_modified_by(translated_locale).to_s)
        .merge(:id => id)
    end

  end
end